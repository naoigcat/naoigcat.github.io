#!/usr/bin/env swift
import Foundation

// Regression: lint/serve must resolve the repo root from #filePath, not cwd,
// so `swift scripts/lint.swift` from a subdirectory still mounts the site root.

struct TestError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }

    init(_ message: String) {
        self.message = message
    }
}

let scriptURL = URL(fileURLWithPath: #filePath).standardizedFileURL
let root = scriptURL.deletingLastPathComponent().deletingLastPathComponent()

func assertFilePathRoot(in path: URL) throws {
    let source = try String(contentsOf: path, encoding: .utf8)
    guard source.contains("#filePath") else {
        throw TestError("\(path.path) must derive the repository root from #filePath")
    }
    if source.contains("FileManager.default.currentDirectoryPath") {
        // Allow currentDirectoryPath only inside helpers that are not the root binding.
        let lines = source.components(separatedBy: .newlines)
        for line in lines where line.contains("currentDirectoryPath") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("let root") || trimmed.contains("let root =") {
                throw TestError("\(path.path) still binds root from the current directory")
            }
        }
    }
}

do {
    try assertFilePathRoot(in: root.appendingPathComponent("scripts/lint.swift"))
    try assertFilePathRoot(in: root.appendingPathComponent("scripts/serve.swift"))
    print("ok: lint.swift and serve.swift resolve the repository root from #filePath")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
