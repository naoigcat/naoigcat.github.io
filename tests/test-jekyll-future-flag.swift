#!/usr/bin/env swift
import Foundation

// Regression: GitHub Pages includes future-dated posts, so every local Docker
// Jekyll invocation must explicitly carry --future.  Checking the Swift
// argument arrays is less fragile than searching for a shell command line.

struct TestError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }

    init(_ message: String) {
        self.message = message
    }
}

let scriptURL = URL(fileURLWithPath: #filePath).standardizedFileURL
let root = scriptURL.deletingLastPathComponent().deletingLastPathComponent()

do {
    let checks: [(URL, [String], String)] = [
        (
            root.appendingPathComponent("scripts/generate-tags-json.swift"),
            ["jekyll", "build", "--future"],
            "jekyll build"
        ),
        (
            root.appendingPathComponent("scripts/serve.swift"),
            ["jekyll", "serve", "--future"],
            "jekyll serve"
        ),
    ]

    for (path, arguments, label) in checks {
        let source = try String(contentsOf: path, encoding: .utf8)
        let compactNeedle = arguments.map { "\"\($0)\"" }.joined(separator: ",")
        let spacedNeedle = arguments.map { "\"\($0)\"" }.joined(separator: ", ")
        guard source.contains(compactNeedle) || source.contains(spacedNeedle) else {
            throw TestError("\(path.path): '\(label)' runs without --future in Docker argv literals")
        }
    }

    print("ok: local Jekyll invocations pass --future")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
