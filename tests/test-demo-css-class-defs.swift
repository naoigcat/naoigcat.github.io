#!/usr/bin/env swift
import Foundation

// Regression: watched demo class names must have a matching selector in
// sort-demo.css whenever a post uses them.  This catches silent visual no-ops
// caused by a typo or by adding a modifier without adding its CSS rule.

struct TestError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }

    init(_ message: String) {
        self.message = message
    }
}

func markdownFiles(under directory: URL) -> [URL] {
    let manager = FileManager.default
    let urls = (manager.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey])?.allObjects ?? [])
        .compactMap { $0 as? URL }
        .filter { $0.pathExtension == "md" }
        .sorted { $0.path < $1.path }
    return urls
}

func cssDefines(_ className: String, in css: String) -> Bool {
    // Word boundaries around the class keep foo from matching foo-bar.
    // NSRegularExpression is used here because CSS selectors are not parsed
    // as Swift identifiers and hyphenated BEM names are common.
    let escaped = NSRegularExpression.escapedPattern(for: className)
    let pattern = "(?<![\\w-])\\.\(escaped)(?![\\w-])"
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
    let range = NSRange(css.startIndex..<css.endIndex, in: css)
    return regex.firstMatch(in: css, range: range) != nil
}

let root = repositoryRoot()
let cssPath = root.appendingPathComponent("assets/css/sort-demo.css")
let postsDirectory = root.appendingPathComponent("_posts")

do {
    let css = try String(contentsOf: cssPath, encoding: .utf8)
    let watched = [
        "burst-demo__tier--ones",
        "burst-demo__tier--tens",
        "sort-demo-unshuffle__incoming-block",
        "sort-demo-unshuffle__merged-block",
        "sort-demo-unshuffle__piles-block",
        "sort-demo__bar--gap",
        "pigeonhole-demo__input",
        "postman-demo__array",
        "veb-demo__canvas",
    ]

    var errors: [String] = []
    for className in watched {
        let hits = markdownFiles(under: postsDirectory).compactMap { path -> String? in
            let text = try? String(contentsOf: path, encoding: .utf8)
            return text?.contains(className) == true
                ? path.path.replacingOccurrences(of: root.path + "/", with: "")
                : nil
        }
        if !hits.isEmpty && !cssDefines(className, in: css) {
            errors.append("\(className): assigned in \(hits.joined(separator: ", ")) but missing from sort-demo.css")
        }
    }

    guard errors.isEmpty else {
        fputs("undefined demo CSS class(es):\n", stderr)
        for error in errors {
            fputs("  \(error)\n", stderr)
        }
        exit(1)
    }
    print("ok: \(watched.count) watched demo class name(s) are defined when used")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
