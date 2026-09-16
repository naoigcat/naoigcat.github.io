#!/usr/bin/env swift
import Foundation

// Regression: lint/serve must resolve the repo root via repositoryRoot()
// (from scripts/support.swift), not cwd, so subdirectory invocations still
// mount the site root.

typealias TestError = ScriptError

let root = repositoryRoot()

func assertUsesSharedRepositoryRoot(in path: URL) throws {
    let source = try String(contentsOf: path, encoding: .utf8)
    guard source.contains("repositoryRoot(") else {
        throw TestError("\(path.path) must call repositoryRoot() from scripts/support.swift")
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
    try assertUsesSharedRepositoryRoot(in: root.appendingPathComponent("scripts/lint.swift"))
    try assertUsesSharedRepositoryRoot(in: root.appendingPathComponent("scripts/serve.swift"))
    let support = try String(
        contentsOf: root.appendingPathComponent("scripts/support.swift"),
        encoding: .utf8
    )
    guard support.contains("#filePath") else {
        throw TestError("scripts/support.swift must walk upward from #filePath")
    }
    print("ok: lint.swift and serve.swift resolve the repository root via support.swift")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
