#!/usr/bin/env swift
import Foundation

// This is the Swift entry point for `mise run lint`.  It deliberately passes
// Docker arguments as an array instead of assembling a shell command, so a
// Markdown path containing spaces or punctuation remains one path argument.
// The default glob and --fix flag are parsed here rather than delegated to
// mise, keeping `.mise.toml` as a thin task dispatcher.

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

func runCommand(
    _ executable: String,
    _ arguments: [String],
    currentDirectory: URL? = nil
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

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    do {
        try process.run()
    } catch {
        throw ScriptError("Could not start \(executable): \(error)")
    }
    process.waitUntilExit()

    let stdout = String(
        data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(),
        encoding: .utf8
    ) ?? ""
    let stderr = String(
        data: stderrPipe.fileHandleForReading.readDataToEndOfFile(),
        encoding: .utf8
    ) ?? ""
    return CommandResult(status: process.terminationStatus, stdout: stdout, stderr: stderr)
}

@discardableResult
func requireCommand(
    _ executable: String,
    _ arguments: [String],
    currentDirectory: URL? = nil
) throws -> CommandResult {
    let result = try runCommand(executable, arguments, currentDirectory: currentDirectory)
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

func projectConfigValue(_ key: String, root: URL) throws -> String {
    // Swift scripts are intentionally standalone, so the shared constants
    // are exposed through config.swift's small CLI instead of a package import.
    let config = root.appendingPathComponent("scripts/config.swift")
    let result = try requireCommand(
        "swift",
        [config.path, key],
        currentDirectory: root
    )
    let value = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty else {
        throw ScriptError("config.swift returned an empty value for \(key)")
    }
    return value
}

let root = URL(fileURLWithPath: #filePath)
    .standardizedFileURL
    .deletingLastPathComponent()
    .deletingLastPathComponent()

do {
    let image = try projectConfigValue("markdownlint-cli2-image", root: root)

    // Task arguments are parsed here for both `mise` and direct Swift
    // invocations, keeping the two entry points behaviorally identical.
    var arguments = Array(CommandLine.arguments.dropFirst())
    if arguments.first == "--" {
        arguments.removeFirst()
    }
    // Both mise task arguments and direct Swift invocations arrive here as
    // ordinary arguments.  There is no hidden environment flag.
    let fix = arguments.contains("--fix")
    arguments.removeAll { $0 == "--fix" }
    if arguments.isEmpty {
        arguments = ["**/*.md"]
    }

    let uid = try requireCommand("id", ["-u"]).stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    let gid = try requireCommand("id", ["-g"]).stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !uid.isEmpty, !gid.isEmpty else {
        throw ScriptError("Failed to resolve uid:gid")
    }

    var dockerArguments = [
        "run", "--rm",
        "--user", "\(uid):\(gid)",
        "--volume", "\(root.path):/workdir",
        "--workdir", "/workdir",
        image,
    ]
    dockerArguments.append(contentsOf: ["--config", ".markdownlint-cli2.jsonc"])
    if fix {
        dockerArguments.append("--fix")
    }
    dockerArguments.append(contentsOf: arguments)

    // Markdownlint output is user-facing, so inherit it directly rather than
    // buffering it.  The command still has no shell layer around it.
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["docker"] + dockerArguments
    process.currentDirectoryURL = root
    process.standardInput = FileHandle.standardInput
    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        exit(process.terminationStatus)
    }
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
