#!/usr/bin/env swift
import Foundation

// Regression: markdownlint image bumps must reject non-dotted VERSION values
// before rewriting scripts/config.swift.  A quote or newline in VERSION would
// otherwise break every mise task that reads the shared Swift config.

struct CommandResult {
    let status: Int32
    let stdout: String
    let stderr: String
}

struct TestError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }

    init(_ message: String) {
        self.message = message
    }
}

func runCommand(
    _ executable: String,
    _ arguments: [String],
    currentDirectory: URL,
    environment: [String: String]
) throws -> CommandResult {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [executable] + arguments
    process.currentDirectoryURL = currentDirectory
    process.environment = environment
    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe
    try process.run()
    process.waitUntilExit()
    return CommandResult(
        status: process.terminationStatus,
        stdout: String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "",
        stderr: String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    )
}

let scriptURL = URL(fileURLWithPath: #filePath).standardizedFileURL
let root = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let syncPath = root.appendingPathComponent("scripts/sync.swift")
let configPath = root.appendingPathComponent("scripts/config.swift")

do {
    let before = try String(contentsOf: configPath, encoding: .utf8)
    let baseEnvironment = ProcessInfo.processInfo.environment

    for bad in ["1.2.3\"; evil", "1.2.3\n4", "v1.2.3", "", "1..2", ".1.2"] {
        var environment = baseEnvironment
        environment["VERSION"] = bad
        let result = try runCommand(
            "swift",
            [syncPath.path, "markdownlint", "update"],
            currentDirectory: root,
            environment: environment
        )
        guard result.status != 0 else {
            throw TestError("expected rejection for VERSION=\(bad.debugDescription)")
        }
        let after = try String(contentsOf: configPath, encoding: .utf8)
        guard after == before else {
            throw TestError("config.swift changed after rejected VERSION=\(bad.debugDescription)")
        }
    }

    let source = try String(contentsOf: syncPath, encoding: .utf8)
    guard source.contains("isDottedVersion") else {
        throw TestError("\(syncPath.path) must validate VERSION with isDottedVersion")
    }
    // The old post-write contains check is meaningless once rewriteAssignment succeeds.
    if let updateRange = source.range(of: "func updateMarkdownlintImage") {
        let body = source[updateRange.lowerBound...]
        let end = body.range(of: "\nfunc ")?.lowerBound ?? body.endIndex
        let fn = String(body[..<end])
        if fn.contains("updated.contains(replacement)") {
            throw TestError("\(syncPath.path) still has a post-write contains guard")
        }
        guard let write = fn.range(of: "write(to:"),
              let validate = fn.range(of: "isDottedVersion"),
              validate.lowerBound < write.lowerBound else {
            throw TestError("\(syncPath.path) must validate VERSION before writing config.swift")
        }
    } else {
        throw TestError("\(syncPath.path) is missing updateMarkdownlintImage")
    }

    print("ok: sync.swift rejects unsafe markdownlint VERSION values before writing")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
