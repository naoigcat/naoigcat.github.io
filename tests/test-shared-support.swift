#!/usr/bin/env swift
import Foundation

// Regression: production Swift tasks must compile with scripts/support.swift,
// and that shared helper must own process capture (no per-script runCommand).

typealias TestError = ScriptError

let root = repositoryRoot()

do {
    let mise = try String(contentsOf: root.appendingPathComponent(".mise.toml"), encoding: .utf8)
    let runLines = mise.components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { $0.hasPrefix("run =") }
    guard !runLines.isEmpty else {
        throw TestError(".mise.toml has no run = lines")
    }
    for line in runLines {
        guard line.contains("scripts/support.swift") else {
            throw TestError(".mise.toml run line missing scripts/support.swift: \(line)")
        }
        guard line.contains("scripts/swift-run.swift") else {
            throw TestError(".mise.toml run line missing scripts/swift-run.swift: \(line)")
        }
    }

    let lint = try String(
        contentsOf: root.appendingPathComponent("scripts/lint.swift"),
        encoding: .utf8
    )
    guard !lint.contains("func runCommand(") else {
        throw TestError("scripts/lint.swift still defines func runCommand(")
    }

    let support = try String(
        contentsOf: root.appendingPathComponent("scripts/support.swift"),
        encoding: .utf8
    )
    guard support.contains("scriptArguments") else {
        throw TestError("scripts/support.swift must define scriptArguments")
    }
    guard support.contains("createFile") else {
        throw TestError("scripts/support.swift must use file-based capture (createFile)")
    }
    // Deadlocking shape: Pipe → waitUntilExit → readDataToEndOfFile.
    if let runRange = support.range(of: "func runCommand(") {
        let after = support[runRange.lowerBound...]
        let end = after.range(
            of: "\nfunc ",
            range: after.index(after: runRange.lowerBound)..<after.endIndex
        )?.lowerBound ?? after.endIndex
        let body = String(after[..<end])
        if body.contains("Pipe()"),
           let wait = body.range(of: "waitUntilExit()"),
           let read = body.range(of: "readDataToEndOfFile()"),
           wait.lowerBound < read.lowerBound {
            throw TestError(
                "scripts/support.swift runCommand still reads pipes after waitUntilExit()"
            )
        }
    } else {
        throw TestError("scripts/support.swift is missing func runCommand(")
    }

    print("ok: mise tasks and scripts/support.swift share process helpers")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
