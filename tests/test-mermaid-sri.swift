#!/usr/bin/env swift
import Foundation

// Regression: the Mermaid CDN URL in head.html must be paired with the
// integrity value belonging to Mermaid itself.  The test skips only the
// network-dependent part when the CDN cannot be reached.

typealias TestError = ScriptError

func firstCapture(_ pattern: String, in text: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
        return nil
    }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges > 1 else {
        return nil
    }
    let capture = match.range(at: 1)
    guard let swiftRange = Range(capture, in: text) else { return nil }
    return String(text[swiftRange])
}

let root = repositoryRoot()
let headPath = root.appendingPathComponent("_includes/head.html")

do {
    let head = try String(contentsOf: headPath, encoding: .utf8)
    let scriptTags = try NSRegularExpression(
        pattern: "<script\\b[\\s\\S]*?</script>",
        options: [.caseInsensitive]
    )
    let headRange = NSRange(head.startIndex..<head.endIndex, in: head)
    let mermaidTag = scriptTags.matches(in: head, range: headRange)
        .compactMap { match -> String? in
            guard let range = Range(match.range, in: head) else { return nil }
            let tag = String(head[range])
            return tag.contains("mermaid@") ? tag : nil
        }
        .first
    guard let mermaidTag else {
        throw TestError("Could not find Mermaid script tag in \(headPath.path)")
    }

    guard let source = firstCapture(
        #"src="(https://cdn\.jsdelivr\.net/npm/mermaid@[^"]+\.js)""#,
        in: mermaidTag
    ) else {
        throw TestError("Could not find Mermaid script src in \(headPath.path)")
    }
    guard let expected = firstCapture(#"integrity="(sha512-[^"]+)""#, in: mermaidTag) else {
        throw TestError("Could not find Mermaid integrity in \(headPath.path)")
    }

    let temporaryDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("mermaid-sri-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
    let body = temporaryDirectory.appendingPathComponent("mermaid.min.js")
    let digestFile = temporaryDirectory.appendingPathComponent("mermaid.sha512")

    // curl is launched directly as a child process.  It is used only for HTTP
    // transfer; no shell pipeline or command interpolation is involved.
    let fetched = try runCommand(
        "curl",
        ["-fsSL", "--connect-timeout", "10", "--max-time", "60", source, "-o", body.path],
        currentDirectory: root
    )
    guard fetched.status == 0 else {
        print("skip: could not fetch Mermaid CDN (\(source)); integrity not verified")
        exit(0)
    }

    // Write binary digest to a file so UTF-8 String capture cannot corrupt it.
    let digest = try runCommand(
        "openssl",
        ["dgst", "-sha512", "-binary", "-out", digestFile.path, body.path],
        currentDirectory: root
    )
    guard digest.status == 0 else {
        throw TestError("Could not calculate SHA-512 for \(source): \(digest.stderr)")
    }
    let digestBytes = try Data(contentsOf: digestFile)
    let actual = "sha512-\(digestBytes.base64EncodedString())"
    guard actual == expected else {
        throw TestError(
            "Mermaid SRI mismatch for \(source)\nhead.html: \(expected)\ncomputed:  \(actual)"
        )
    }

    print("ok: Mermaid SRI matches CDN (\(source))")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
