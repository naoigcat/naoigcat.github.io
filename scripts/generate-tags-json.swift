#!/usr/bin/env swift
import Foundation

// Regenerates assets/tags/*.json from a Docker Jekyll export.
// No Package.swift — run via
// `swift scripts/swift-run.swift scripts/generate-tags-json.swift scripts/support.swift`
// (mise task `tags`).

func projectConfigValue(_ key: String, root: URL) throws -> String {
  // Standalone scripts cannot share declarations through a package import.
  // config.swift therefore exposes the two typed constants through a tiny CLI.
  let config = root.appendingPathComponent("scripts/config.swift")
  let value = try requireCommand("swift", [config.path, key], currentDirectory: root)
    .stdout.trimmingCharacters(in: .whitespacesAndNewlines)
  guard !value.isEmpty else {
    throw ScriptError("config.swift returned an empty value for \(key)")
  }
  return value
}

func posixUserGroup() throws -> String {
  let uid = try requireCommand("/usr/bin/id", ["-u"])
    .stdout.trimmingCharacters(in: .whitespacesAndNewlines)
  let gid = try requireCommand("/usr/bin/id", ["-g"])
    .stdout.trimmingCharacters(in: .whitespacesAndNewlines)
  guard !uid.isEmpty, !gid.isEmpty else {
    throw ScriptError("Failed to resolve uid:gid")
  }
  return "\(uid):\(gid)"
}

// MARK: - JSON (Python json.dumps(ensure_ascii=False, indent=2) compatible)

enum JSONValue {
  case object([(String, JSONValue)])
  case array([JSONValue])
  case string(String)
  case number(String)
  case bool(Bool)
  case null
}

func parseJSONValue(_ data: Data) throws -> JSONValue {
  let obj = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
  return try bridgeJSON(obj)
}

func bridgeJSON(_ any: Any) throws -> JSONValue {
  switch any {
  case is NSNull:
    return .null
  case let n as NSNumber:
    // Bool is bridged as NSNumber.  `objCType` is available in Foundation on
    // both Darwin and Linux, while the CoreFoundation type-id functions are
    // not imported consistently by the Linux Swift toolchain.
    if String(cString: n.objCType) == "c" {
      return .bool(n.boolValue)
    }
    return .number(n.stringValue)
  case let s as String:
    return .string(s)
  case let arr as [Any]:
    return .array(try arr.map(bridgeJSON))
  case let dict as [String: Any]:
    // NSDictionary loses key order; for tag objects we re-order below when writing.
    return .object(try dict.map { ($0.key, try bridgeJSON($0.value)) })
  default:
    throw ScriptError("Unsupported JSON value \(type(of: any))")
  }
}

func jsonEscape(_ string: String) -> String {
  var out = "\""
  for ch in string {
    switch ch {
    case "\"": out += "\\\""
    case "\\": out += "\\\\"
    case "\n": out += "\\n"
    case "\r": out += "\\r"
    case "\t": out += "\\t"
    case "\u{8}": out += "\\b"
    case "\u{c}": out += "\\f"
    default:
      if ch.unicodeScalars.count == 1, let s = ch.unicodeScalars.first, s.value < 0x20 {
        out += String(format: "\\u%04x", s.value)
      } else {
        out.append(ch)
      }
    }
  }
  out += "\""
  return out
}

func dumpJSON(_ value: JSONValue, indent: Int = 0) -> String {
  let pad = String(repeating: "  ", count: indent)
  let inner = String(repeating: "  ", count: indent + 1)
  switch value {
  case .null:
    return "null"
  case .bool(let b):
    return b ? "true" : "false"
  case .number(let n):
    return n
  case .string(let s):
    return jsonEscape(s)
  case .array(let items):
    if items.isEmpty { return "[]" }
    var lines = ["["]
    for (i, item) in items.enumerated() {
      let comma = i + 1 < items.count ? "," : ""
      lines.append("\(inner)\(dumpJSON(item, indent: indent + 1))\(comma)")
    }
    lines.append("\(pad)]")
    return lines.joined(separator: "\n")
  case .object(let pairs):
    if pairs.isEmpty { return "{}" }
    var lines = ["{"]
    for (i, pair) in pairs.enumerated() {
      let comma = i + 1 < pairs.count ? "," : ""
      lines.append("\(inner)\(jsonEscape(pair.0)): \(dumpJSON(pair.1, indent: indent + 1))\(comma)")
    }
    lines.append("\(pad)}")
    return lines.joined(separator: "\n")
  }
}

func orderedTagObject(_ value: JSONValue) throws -> JSONValue {
  guard case .object(let pairs) = value else {
    throw ScriptError("Expected tag object")
  }
  let map = Dictionary(uniqueKeysWithValues: pairs)
  guard let name = map["name"], let slug = map["slug"], let posts = map["posts"] else {
    throw ScriptError("Tag object missing name/slug/posts")
  }
  let orderedPosts: JSONValue
  if case .array(let items) = posts {
    orderedPosts = .array(try items.map { post -> JSONValue in
      guard case .object(let pp) = post else {
        throw ScriptError("posts[] must be objects")
      }
      let pm = Dictionary(uniqueKeysWithValues: pp)
      guard let title = pm["title"], let url = pm["url"], let date = pm["date"] else {
        throw ScriptError("post missing title/url/date")
      }
      return .object([("title", title), ("url", url), ("date", date)])
    })
  } else {
    throw ScriptError("posts must be an array")
  }
  return .object([("name", name), ("slug", slug), ("posts", orderedPosts)])
}

func stringField(_ value: JSONValue, _ key: String) throws -> String {
  guard case .object(let pairs) = value,
        let found = pairs.first(where: { $0.0 == key })?.1,
        case .string(let s) = found
  else {
    throw ScriptError("Missing string field \(key)")
  }
  return s
}

// MARK: - Main flows

func writeTagFiles(exportFile: URL, destDir: URL) throws {
  let data = try Data(contentsOf: exportFile)
  let root = try parseJSONValue(data)
  guard case .array(let tags) = root else {
    throw ScriptError("Export root must be a JSON array")
  }

  try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

  var slugToName: [String: String] = [:]
  var seen = Set<String>()

  for raw in tags {
    let tag = try orderedTagObject(raw)
    let slug = try stringField(tag, "slug")
    let name = try stringField(tag, "name")
    if let existing = slugToName[slug], existing != name {
      throw ScriptError(
        "Tag slug collision: \(slug.debugDescription) is used by both \(existing.debugDescription) and \(name.debugDescription)"
      )
    }
    slugToName[slug] = name
    seen.insert(slug)
    let path = destDir.appendingPathComponent("\(slug).json")
    let text = dumpJSON(tag) + "\n"
    try text.write(to: path, atomically: true, encoding: .utf8)
  }

  let existing = try FileManager.default.contentsOfDirectory(
    at: destDir,
    includingPropertiesForKeys: nil
  )
  for path in existing where path.pathExtension == "json" {
    if !seen.contains(path.deletingPathExtension().lastPathComponent) {
      try FileManager.default.removeItem(at: path)
    }
  }

  fputs("Wrote \(seen.count) tag JSON files to \(destDir.path)\n", stderr)
}

func generateTags() throws {
  let root = repositoryRoot()
  let pagesImage = try projectConfigValue("github-pages-image", root: root)

  let outDir = root.appendingPathComponent("assets/tags")

  do {
    try requireCommand("docker", ["info"], discardStdout: true)
  } catch {
    throw ScriptError("Docker is not available. Start Docker and retry.")
  }

  let workdir = FileManager.default.temporaryDirectory
    .appendingPathComponent("generate-tags-json-\(UUID().uuidString)")
  try FileManager.default.createDirectory(at: workdir, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: workdir) }

  try requireCommand(
    "rsync",
    [
      "-a",
      "--exclude", ".git",
      "--exclude", "_site",
      "--exclude", "assets/tags",
      "\(root.path)/",
      "\(workdir.path)/",
    ]
  )

  let layouts = workdir.appendingPathComponent("_layouts")
  try FileManager.default.createDirectory(at: layouts, withIntermediateDirectories: true)
  try "{{ content }}\n".write(
    to: layouts.appendingPathComponent("null.html"),
    atomically: true,
    encoding: .utf8
  )

  let liquid = """
  ---
  layout: null
  markdown: false
  ---
  [
  {%- assign sorted_tags = site.tags | sort -%}
  {%- for tag in sorted_tags -%}
  {%- assign tag_name = tag[0] -%}
  {%- unless forloop.first -%},{%- endunless -%}
  {% include tags-tag-json-full.html name=tag_name %}
  {%- endfor -%}
  ]
  """
  try liquid.write(
    to: workdir.appendingPathComponent("export-all-tags.html"),
    atomically: true,
    encoding: .utf8
  )

  let userGroup = try posixUserGroup()
  // GitHub Pages builds with `future: true`, so future-dated posts are live there;
  // match it, or their tags silently vanish from (or get deleted under) assets/tags.
  try requireCommand(
    "docker",
    [
      "run", "--rm",
      "--user", userGroup,
      "-v", "\(workdir.path):/work",
      pagesImage,
      "jekyll", "build", "--future", "-s", "/work", "-d", "/work/_site",
    ],
    discardStdout: true
  )

  let exportFile = workdir.appendingPathComponent("_site/export-all-tags.html")
  guard FileManager.default.isReadableFile(atPath: exportFile.path) else {
    throw ScriptError("Export file not found: \(exportFile.path)")
  }
  try writeTagFiles(exportFile: exportFile, destDir: outDir)
}

// MARK: - Entry

let args = scriptArguments()
do {
  if args.isEmpty {
    try generateTags()
  } else {
    throw ScriptError("usage: generate-tags-json.swift")
  }
} catch {
  fputs("\(error)\n", stderr)
  exit(1)
}
