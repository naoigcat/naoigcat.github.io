#!/usr/bin/env swift
import Foundation

// Shared helpers for standalone multi-file script invocations.
//
// Swift 6+ only interprets the first path passed to `swift`, so production
// entry points use:
//   swift scripts/swift-run.swift <main.swift> scripts/support.swift [args...]
// `scriptArguments()` still drops any leftover `.swift` paths from argv.
// This file must not execute top-level work; it only declares types and functions.

struct CommandResult {
    let status: Int32
    let stdout: String
    let stderr: String
}

struct ScriptError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }

    init(_ message: String) {
        self.message = message
    }
}

/// Drops companion `.swift` sources that Swift includes in CommandLine.arguments
/// when multiple files are compiled together.
func scriptArguments() -> [String] {
    Array(CommandLine.arguments.dropFirst().filter { !$0.hasSuffix(".swift") })
}

func repositoryRoot(startingAt filePath: String = #filePath) -> URL {
    if let override = ProcessInfo.processInfo.environment["LEARNINGS_REPO_ROOT"],
       !override.isEmpty {
        return URL(fileURLWithPath: override).standardizedFileURL
    }
    if let workspace = ProcessInfo.processInfo.environment["GITHUB_WORKSPACE"],
       !workspace.isEmpty {
        return URL(fileURLWithPath: workspace).standardizedFileURL
    }

    func walk(from filePath: String) -> URL? {
        var directory = URL(fileURLWithPath: filePath).standardizedFileURL.deletingLastPathComponent()
        while true {
            if FileManager.default.fileExists(atPath: directory.appendingPathComponent("_config.yml").path) {
                return directory
            }
            let parent = directory.deletingLastPathComponent()
            if parent.path == directory.path {
                return nil
            }
            directory = parent
        }
    }

    if let rooted = walk(from: filePath) {
        return rooted
    }
    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath).standardizedFileURL
}

/// Captures child stdout/stderr via temp files so large output cannot deadlock
/// a pipe buffer while the parent waits for exit.
func runCommand(
    _ executable: String,
    _ arguments: [String],
    currentDirectory: URL? = nil,
    environment: [String: String]? = nil,
    discardStdout: Bool = false,
    inheritIO: Bool = false
) throws -> CommandResult {
    let process = Process()
    if executable.hasPrefix("/") {
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
    } else {
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [executable] + arguments
    }
    process.currentDirectoryURL = currentDirectory
    if let environment {
        process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }
    }

    if inheritIO {
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError
        do {
            try process.run()
        } catch {
            throw ScriptError("Could not start \(executable): \(error)")
        }
        process.waitUntilExit()
        return CommandResult(status: process.terminationStatus, stdout: "", stderr: "")
    }

    let temporaryDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("run-command-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

    let stderrFile = temporaryDirectory.appendingPathComponent("stderr")
    guard FileManager.default.createFile(atPath: stderrFile.path, contents: nil),
          let stderrHandle = FileHandle(forWritingAtPath: stderrFile.path) else {
        throw ScriptError("Could not open stderr capture file")
    }

    let stdoutFile = temporaryDirectory.appendingPathComponent("stdout")
    let stdoutHandle: FileHandle
    if discardStdout {
        stdoutHandle = .nullDevice
    } else {
        guard FileManager.default.createFile(atPath: stdoutFile.path, contents: nil),
              let handle = FileHandle(forWritingAtPath: stdoutFile.path) else {
            throw ScriptError("Could not open stdout capture file")
        }
        stdoutHandle = handle
    }

    process.standardOutput = stdoutHandle
    process.standardError = stderrHandle
    do {
        try process.run()
    } catch {
        if !discardStdout {
            try? stdoutHandle.close()
        }
        try? stderrHandle.close()
        throw ScriptError("Could not start \(executable): \(error)")
    }
    process.waitUntilExit()
    if !discardStdout {
        try? stdoutHandle.close()
    }
    try? stderrHandle.close()

    let stdout = discardStdout ? "" : (try String(contentsOf: stdoutFile, encoding: .utf8))
    let stderr = try String(contentsOf: stderrFile, encoding: .utf8)
    return CommandResult(status: process.terminationStatus, stdout: stdout, stderr: stderr)
}

@discardableResult
func requireCommand(
    _ executable: String,
    _ arguments: [String],
    currentDirectory: URL? = nil,
    environment: [String: String]? = nil,
    discardStdout: Bool = false,
    inheritIO: Bool = false
) throws -> CommandResult {
    let result = try runCommand(
        executable,
        arguments,
        currentDirectory: currentDirectory,
        environment: environment,
        discardStdout: discardStdout,
        inheritIO: inheritIO
    )
    guard result.status == 0 else {
        let detail = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        throw ScriptError(
            detail.isEmpty
                ? "Command failed (\(result.status)): \(executable) \(arguments.joined(separator: " "))"
                : detail
        )
    }
    return result
}

@discardableResult
func runInherited(_ executable: String, _ arguments: [String], currentDirectory: URL? = nil) throws -> Int32 {
    try requireCommand(
        executable,
        arguments,
        currentDirectory: currentDirectory,
        inheritIO: true
    ).status
}

/// Status-only helper that discards child output (no unread pipes).
func runStatus(_ executable: String, _ arguments: [String], currentDirectory: URL? = nil) throws -> Int32 {
    let process = Process()
    if executable.hasPrefix("/") {
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
    } else {
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [executable] + arguments
    }
    process.currentDirectoryURL = currentDirectory
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    do {
        try process.run()
    } catch {
        throw ScriptError("Could not start \(executable): \(error)")
    }
    process.waitUntilExit()
    return process.terminationStatus
}
