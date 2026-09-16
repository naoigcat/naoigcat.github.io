#!/usr/bin/env swift
import Foundation

// Regression: JSON embedded inside the /tags/ script element must escape the
// less-than sign.  Otherwise a title containing </script> could terminate the
// JSON element before the browser's JSON parser sees it.

typealias TestError = ScriptError

func regularFiles(under directory: URL) -> [URL] {
    (FileManager.default.enumerator(
        at: directory,
        includingPropertiesForKeys: [.isRegularFileKey]
    )?.allObjects ?? [])
        .compactMap { $0 as? URL }
        .sorted { $0.path < $1.path }
}

/// Copies a repository tree while omitting generated and VCS directories.
///
/// A custom copier lets the test use Swift filesystem APIs even when rsync is
/// unavailable on a minimal CI image.  The exclusions mirror the old rsync
/// command and prevent generated tag JSON from being copied into the fixture.
func copyTree(from source: URL, to destination: URL, relativePath: String) throws {
    let excluded = [
        ".git",
        "_site",
        "assets/tags",
    ]
    if excluded.contains(relativePath) || relativePath.hasPrefix(".tmp-tags-script-escape") {
        return
    }

    var isDirectory = ObjCBool(false)
    guard FileManager.default.fileExists(atPath: source.path, isDirectory: &isDirectory) else {
        return
    }
    if isDirectory.boolValue {
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        for child in try FileManager.default.contentsOfDirectory(
            at: source,
            includingPropertiesForKeys: nil,
            options: []
        ).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let childRelative = relativePath.isEmpty
                ? child.lastPathComponent
                : "\(relativePath)/\(child.lastPathComponent)"
            try copyTree(
                from: child,
                to: destination.appendingPathComponent(child.lastPathComponent),
                relativePath: childRelative
            )
        }
    } else {
        try FileManager.default.copyItem(at: source, to: destination)
    }
}

func firstCapture(_ pattern: String, in text: String) -> (String, NSRange)? {
    let regex = try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    guard let match = regex.firstMatch(in: text, range: range),
          match.numberOfRanges > 1,
          let capture = Range(match.range(at: 1), in: text) else {
        return nil
    }
    return (String(text[capture]), match.range)
}

let root = repositoryRoot()
let headFiles = ["tags/index.html", "_includes/tags-tag-json-full.html"]

do {
    let required = "jsonify | replace: '<', '\\u003c'"
    let bareJSONPattern = try NSRegularExpression(pattern: #"[|]\s*jsonify\s*\}\}"#)
    for relative in headFiles {
        let path = root.appendingPathComponent(relative)
        let text = try String(contentsOf: path, encoding: .utf8)
        guard text.contains(required) else {
            throw TestError("\(relative): missing jsonify | replace escape for script-safe JSON")
        }

        // Every jsonify in these templates must be followed by the replace
        // filter on the same source line; a bare jsonify is unsafe in HTML.
        for line in text.components(separatedBy: .newlines) {
            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            if bareJSONPattern.firstMatch(in: line, range: range) != nil && !line.contains("replace:") {
                throw TestError("\(relative): found jsonify without | replace: '<', '\\u003c'")
            }
        }
    }

    let projectConfigPath = root.appendingPathComponent("scripts/config.swift")
    let imageResult = try requireCommand(
        "swift",
        [projectConfigPath.path, "github-pages-image"],
        currentDirectory: root
    )
    let image = imageResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !image.isEmpty else {
        throw TestError("Could not read githubPagesImage from scripts/config.swift")
    }

    // Source assertions above remain useful offline.  The following render
    // assertion is conditional because a CDN-independent test should not make
    // the whole repository unusable when Docker is stopped.
    let dockerInfo = try runCommand("docker", ["info"], currentDirectory: root)
    guard dockerInfo.status == 0 else {
        print("skip: Docker is not available; source escape checked only")
        exit(0)
    }

    var workdir = FileManager.default.temporaryDirectory
        .appendingPathComponent("tags-script-escape-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: workdir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: workdir) }

    // Prefer the system temporary directory, but use a unique workspace-local
    // directory when the Docker VM cannot bind-mount the system path.
    let probe = try runCommand(
        "docker",
        ["run", "--rm", "-v", "\(workdir.path):/work", image, "true"],
        currentDirectory: root
    )
    if probe.status != 0 {
        try FileManager.default.removeItem(at: workdir)
        workdir = root.appendingPathComponent(".tmp-tags-script-escape-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: workdir, withIntermediateDirectories: true)
    }
    try copyTree(from: root, to: workdir, relativePath: "")

    let configPath = workdir.appendingPathComponent("_config.yml")
    var config = try String(contentsOf: configPath, encoding: .utf8)
    let title = #"title: "Leak </script><script>alert(1)</script>""#
    let titleRegex = try NSRegularExpression(pattern: #"^title:\s*.*$"#, options: [.anchorsMatchLines])
    let configRange = NSRange(config.startIndex..<config.endIndex, in: config)
    if titleRegex.firstMatch(in: config, range: configRange) != nil {
        config = titleRegex.stringByReplacingMatches(in: config, range: configRange, withTemplate: title)
    } else {
        config = title + "\n" + config
    }
    try config.write(to: configPath, atomically: true, encoding: .utf8)

    let uid = try requireCommand("id", ["-u"], currentDirectory: root)
        .stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    let gid = try requireCommand("id", ["-g"], currentDirectory: root)
        .stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    _ = try requireCommand(
        "docker",
        [
            "run", "--rm",
            "--user", "\(uid):\(gid)",
            "-v", "\(workdir.path):/work",
            image,
            "jekyll", "build", "-s", "/work", "-d", "/work/_site",
        ],
        currentDirectory: root
    )

    let built = workdir.appendingPathComponent("_site/tags/index.html")
    guard FileManager.default.fileExists(atPath: built.path) else {
        throw TestError("Built tags page missing: \(built.path)")
    }
    let html = try String(contentsOf: built, encoding: .utf8)
    guard let captured = firstCapture(
        #"<script type="application/json" id="tags-data">(.*?)</script>"#,
        in: html
    ) else {
        throw TestError("tags-data script block not found in built /tags/")
    }
    let payload = captured.0
    guard !payload.contains("</script>") else {
        throw TestError("raw </script> remains inside tags-data JSON payload")
    }
    guard let data = payload.data(using: .utf8),
          let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let siteTitle = json["siteTitle"] as? String,
          siteTitle.contains("<"),
          siteTitle.contains("script") else {
        throw TestError("expected decoded siteTitle to contain <script…>")
    }
    guard let fullMatch = Range(captured.1, in: html),
          html[fullMatch].contains("\\u003c") else {
        throw TestError("expected \\u003c escapes in tags-data HTML source")
    }

    print("ok: tags-data escapes </script> in JSON-in-script embedding")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
