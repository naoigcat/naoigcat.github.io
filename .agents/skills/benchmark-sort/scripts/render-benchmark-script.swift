#!/usr/bin/env swift
import Foundation

// Renders the benchmark include in an isolated Jekyll site and extracts the
// executable program from the generated HTML.  This used to be a Bash script
// with an embedded Python HTML parser; keeping the whole adapter in Swift
// makes it usable from the Swift benchmark updater as well.

func projectConfigValue(_ key: String, root: URL) throws -> String {
    // Standalone scripts cannot import another script as a module.  The shared
    // config file therefore exposes its typed constants through a tiny CLI.
    let config = root.appendingPathComponent("scripts/config.swift")
    let result = try requireCommand(
        "swift",
        [config.path, key],
        currentDirectory: root
    )
    let value = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty else {
        throw ScriptError("config.swift returned an empty value for \(key)")
    }
    return value
}

func decodeHTMLEntities(_ text: String) -> String {
    // Jekyll escapes the generated source for the HTML code element.  Decode
    // exactly once, just as HTMLParser.handle_data did in the old adapter.
    var result = ""
    var cursor = text.startIndex
    while cursor < text.endIndex {
        guard text[cursor] == "&",
              let semicolon = text[cursor...].firstIndex(of: ";") else {
            result.append(text[cursor])
            cursor = text.index(after: cursor)
            continue
        }

        let entity = String(text[cursor...semicolon])
        let decoded: String?
        switch entity {
        case "&quot;": decoded = "\""
        case "&apos;": decoded = "'"
        case "&#39;": decoded = "'"
        case "&lt;": decoded = "<"
        case "&gt;": decoded = ">"
        case "&amp;": decoded = "&"
        default:
            if entity.hasPrefix("&#x") || entity.hasPrefix("&#X") {
                let digits = entity.dropFirst(3).dropLast()
                decoded = UInt32(digits, radix: 16).flatMap(UnicodeScalar.init).map(String.init)
            } else if entity.hasPrefix("&#") {
                let digits = entity.dropFirst(2).dropLast()
                decoded = UInt32(digits).flatMap(UnicodeScalar.init).map(String.init)
            } else {
                decoded = nil
            }
        }

        if let decoded {
            result += decoded
            cursor = text.index(after: semicolon)
        } else {
            result.append(text[cursor])
            cursor = text.index(after: cursor)
        }
    }
    return result
}

func removeSyntaxHighlightTags(_ fragment: String) -> String {
    // Rouge wraps highlighted tokens in span elements.  HTMLParser used to
    // expose only their text nodes; this small scanner provides the same
    // behavior without treating encoded source characters as HTML tags.
    var result = ""
    var cursor = fragment.startIndex
    while cursor < fragment.endIndex {
        if fragment[cursor] == "<",
           let closing = fragment[cursor...].firstIndex(of: ">") {
            cursor = fragment.index(after: closing)
        } else {
            result.append(fragment[cursor])
            cursor = fragment.index(after: cursor)
        }
    }
    return result
}

func extractCode(from html: String) throws -> String {
    guard let target = html.range(of: "<div class=\"sort-benchmark-code\"") else {
        throw ScriptError("Benchmark code container was not rendered")
    }
    let afterTarget = target.upperBound..<html.endIndex
    guard let codeTag = html.range(of: "<code", range: afterTarget),
          let openingEnd = html[codeTag.upperBound...].firstIndex(of: ">"),
          let closing = html.range(of: "</code>", range: html.index(after: openingEnd)..<html.endIndex) else {
        throw ScriptError("Benchmark code element was not rendered")
    }

    let encoded = String(html[html.index(after: openingEnd)..<closing.lowerBound])
    let textNodes = removeSyntaxHighlightTags(encoded)
    let source = decodeHTMLEntities(textNodes).trimmingCharacters(in: .whitespacesAndNewlines)
    guard !source.isEmpty else {
        throw ScriptError("Rendered benchmark code is empty")
    }
    return source
}

let arguments = scriptArguments()
let root = repositoryRoot()

do {
    guard arguments.count == 1 else {
        throw ScriptError("usage: render-benchmark-script.swift <algorithm>")
    }
    let algorithm = arguments[0]
    let pagesImage = try projectConfigValue("github-pages-image", root: root)
    try requireCommand("docker", ["info"], currentDirectory: root, discardStdout: true)

    let workdir = FileManager.default.temporaryDirectory
        .appendingPathComponent("render-benchmark-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: workdir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: workdir) }

    // Only the include tree and its data file are needed for this render.  A
    // minimal copy keeps unrelated posts and generated assets out of Docker.
    let includes = workdir.appendingPathComponent("_includes")
    let data = workdir.appendingPathComponent("_data")
    try FileManager.default.createDirectory(at: includes, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: data, withIntermediateDirectories: true)
    try FileManager.default.copyItem(
        at: root.appendingPathComponent("_includes/sort-benchmark"),
        to: includes.appendingPathComponent("sort-benchmark")
    )
    try FileManager.default.copyItem(
        at: root.appendingPathComponent("_includes/sort-benchmark.md"),
        to: includes.appendingPathComponent("sort-benchmark.md")
    )
    try FileManager.default.copyItem(
        at: root.appendingPathComponent("_data/sort_algorithms.yml"),
        to: data.appendingPathComponent("sort_algorithms.yml")
    )

    try """
    title: benchmark-render
    theme: null
    plugins: []
    """.write(
        to: workdir.appendingPathComponent("_config.yml"),
        atomically: true,
        encoding: .utf8
    )
    let layouts = workdir.appendingPathComponent("_layouts")
    try FileManager.default.createDirectory(at: layouts, withIntermediateDirectories: true)
    try "{{ content }}\n".write(
        to: layouts.appendingPathComponent("null.html"),
        atomically: true,
        encoding: .utf8
    )
    try """
    ---
    layout: null
    ---
    {% include sort-benchmark.md algorithm="\(algorithm)" %}
    """.write(
        to: workdir.appendingPathComponent("render.md"),
        atomically: true,
        encoding: .utf8
    )

    let user = try requireCommand("id", ["-u"], currentDirectory: root)
        .stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    let group = try requireCommand("id", ["-g"], currentDirectory: root)
        .stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !user.isEmpty, !group.isEmpty else {
        throw ScriptError("Failed to resolve uid:gid")
    }

    try requireCommand(
        "docker",
        [
            "run", "--rm",
            "--user", "\(user):\(group)",
            "-v", "\(workdir.path):/work",
            pagesImage,
            "jekyll", "build", "-s", "/work", "-d", "/work/_site",
        ],
        currentDirectory: root,
        discardStdout: true
    )

    let rendered = workdir.appendingPathComponent("_site/render.html")
    guard FileManager.default.isReadableFile(atPath: rendered.path) else {
        throw ScriptError("Rendered HTML not found: \(rendered.path)")
    }
    let source = try extractCode(from: String(contentsOf: rendered, encoding: .utf8))
    guard source.hasPrefix("#!/usr/bin/env swift") else {
        throw ScriptError("Rendered benchmark is not a standalone Swift program: \(String(source.prefix(80)).debugDescription)")
    }
    print(source)
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
