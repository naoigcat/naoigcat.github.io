#!/usr/bin/env swift
import Foundation

// Regression: runCommand must not waitUntilExit before draining captured
// stdout/stderr.  A child that writes more than the pipe buffer (~64 KiB)
// would otherwise block forever with no error.

struct TestError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }

    init(_ message: String) {
        self.message = message
    }
}

struct CommandResult {
    let status: Int32
    let stdout: String
    let stderr: String
}

/// Mirrors the fixed update-benchmark runCommand capture strategy.
func runCommandCapturingToFiles(
    _ executable: String,
    _ arguments: [String],
    currentDirectory: URL,
    discardStdout: Bool = false
) throws -> CommandResult {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [executable] + arguments
    process.currentDirectoryURL = currentDirectory

    let temporaryDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("run-command-test-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

    let stderrFile = temporaryDirectory.appendingPathComponent("stderr")
    guard FileManager.default.createFile(atPath: stderrFile.path, contents: nil),
          let stderrHandle = FileHandle(forWritingAtPath: stderrFile.path) else {
        throw TestError("Could not open stderr capture file")
    }

    let stdoutFile = temporaryDirectory.appendingPathComponent("stdout")
    let stdoutHandle: FileHandle
    if discardStdout {
        stdoutHandle = .nullDevice
    } else {
        guard FileManager.default.createFile(atPath: stdoutFile.path, contents: nil),
              let handle = FileHandle(forWritingAtPath: stdoutFile.path) else {
            throw TestError("Could not open stdout capture file")
        }
        stdoutHandle = handle
    }

    process.standardOutput = stdoutHandle
    process.standardError = stderrHandle
    try process.run()
    process.waitUntilExit()
    if !discardStdout {
        try? stdoutHandle.close()
    }
    try? stderrHandle.close()

    let stdout = discardStdout ? "" : (try String(contentsOf: stdoutFile, encoding: .utf8))
    let stderr = try String(contentsOf: stderrFile, encoding: .utf8)
    return CommandResult(status: process.terminationStatus, stdout: stdout, stderr: stderr)
}

let scriptURL = URL(fileURLWithPath: #filePath).standardizedFileURL
let root = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let updateScript = root.appendingPathComponent(
    ".agents/skills/benchmark-sort/scripts/update-benchmark.swift"
)

do {
    let source = try String(contentsOf: updateScript, encoding: .utf8)
    guard let teeRange = source.range(of: "func runCommand(") else {
        throw TestError("\(updateScript.path) is missing runCommand")
    }
    let after = source[teeRange.lowerBound...]
    guard let nextFunc = after.range(
        of: "\nfunc ",
        range: after.index(after: teeRange.lowerBound)..<after.endIndex
    ) else {
        throw TestError("\(updateScript.path): could not bound runCommand")
    }
    let body = String(after[..<nextFunc.lowerBound])

    // The deadlocking shape is: Pipe → waitUntilExit → readDataToEndOfFile.
    if body.contains("Pipe()"),
       let wait = body.range(of: "waitUntilExit()"),
       let read = body.range(of: "readDataToEndOfFile()"),
       wait.lowerBound < read.lowerBound {
        throw TestError(
            "\(updateScript.path): runCommand still reads pipes after waitUntilExit()"
        )
    }

    // Behavioral check: >64 KiB must complete when captured via files.
    let childDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("pipe-drain-child-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: childDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: childDirectory) }
    let child = childDirectory.appendingPathComponent("emit.swift")
    let payloadSize = 100_000
    try """
    import Foundation
    FileHandle.standardOutput.write(Data(repeating: 0x61, count: \(payloadSize)))
    """.write(to: child, atomically: true, encoding: .utf8)

    let result = try runCommandCapturingToFiles(
        "swift",
        [child.path],
        currentDirectory: childDirectory
    )
    guard result.status == 0 else {
        throw TestError("large-stdout child failed: \(result.stderr)")
    }
    guard result.stdout.utf8.count == payloadSize else {
        throw TestError(
            "expected \(payloadSize) stdout bytes, got \(result.stdout.utf8.count)"
        )
    }

    print("ok: update-benchmark runCommand avoids pipe deadlock on large stdout")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
