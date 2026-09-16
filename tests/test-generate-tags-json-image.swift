#!/usr/bin/env swift
import Foundation

// Regression: Docker image constants belong to the shared Swift config, while
// mise remains a task dispatcher with no duplicated values or flag schema.

typealias TestError = ScriptError

let root = repositoryRoot()
do {
    let config = root.appendingPathComponent("scripts/config.swift")
    let configText = try String(contentsOf: config, encoding: .utf8)
    guard configText.contains("static let githubPagesImage"),
          configText.contains("static let markdownlintCLI2Image") else {
        throw TestError("scripts/config.swift is missing a Docker image constant")
    }

    let values = [
        ("github-pages-image", "naoigcat/github-pages:"),
        ("markdownlint-cli2-image", "davidanson/markdownlint-cli2:v"),
    ]
    for (key, expected) in values {
        let result = try runCommand(
            "swift",
            [config.path, key],
            currentDirectory: root
        )
        guard result.status == 0 else {
            throw TestError("config.swift \(key) failed: \(result.stderr)")
        }
        let actual = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        let suffix = actual.hasPrefix(expected) ? String(actual.dropFirst(expected.count)) : ""
        guard actual.hasPrefix(expected),
              !suffix.isEmpty,
              suffix.allSatisfy({ $0.isNumber || $0 == "." }) else {
            throw TestError("config.swift \(key): expected prefix \(expected), got \(actual)")
        }
    }

    // The task file must remain a dispatcher: no variable table or flag
    // declaration is allowed to become a second source of configuration.
    let mise = try String(contentsOf: root.appendingPathComponent(".mise.toml"), encoding: .utf8)
    guard !mise.contains("[vars]"), !mise.contains("usage =") else {
        throw TestError(".mise.toml still contains variables or usage flags")
    }
    let expectedRuns = [
        "run = \"swift scripts/swift-run.swift scripts/serve.swift scripts/support.swift\"",
        "run = \"swift scripts/swift-run.swift scripts/lint.swift scripts/support.swift\"",
        "run = \"swift scripts/swift-run.swift scripts/generate-tags-json.swift scripts/support.swift\"",
        "run = \"swift scripts/swift-run.swift tests/run.swift scripts/support.swift\"",
    ]
    let runLines = mise.components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { $0.hasPrefix("run =") }
    guard runLines.count == expectedRuns.count,
          expectedRuns.allSatisfy({ runLines.contains($0) }) else {
        throw TestError(".mise.toml must only dispatch the four Swift task scripts")
    }

    print("ok: Swift config owns Docker images and mise has no task variables")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
