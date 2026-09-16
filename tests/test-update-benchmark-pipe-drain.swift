#!/usr/bin/env swift
import Foundation

// Regression: shared runCommand must not waitUntilExit before draining captured
// stdout/stderr.  A child that writes more than the pipe buffer (~64 KiB)
// would otherwise block forever with no error.

typealias TestError = ScriptError

let root = repositoryRoot()
let supportScript = root.appendingPathComponent("scripts/support.swift")

do {
    let source = try String(contentsOf: supportScript, encoding: .utf8)
    guard let runRange = source.range(of: "func runCommand(") else {
        throw TestError("\(supportScript.path) is missing runCommand")
    }
    let after = source[runRange.lowerBound...]
    guard let nextFunc = after.range(
        of: "\nfunc ",
        range: after.index(after: runRange.lowerBound)..<after.endIndex
    ) else {
        throw TestError("\(supportScript.path): could not bound runCommand")
    }
    let body = String(after[..<nextFunc.lowerBound])

    // The deadlocking shape is: Pipe → waitUntilExit → readDataToEndOfFile.
    if body.contains("Pipe()"),
       let wait = body.range(of: "waitUntilExit()"),
       let read = body.range(of: "readDataToEndOfFile()"),
       wait.lowerBound < read.lowerBound {
        throw TestError(
            "\(supportScript.path): runCommand still reads pipes after waitUntilExit()"
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

    let result = try runCommand(
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

    print("ok: support.swift runCommand avoids pipe deadlock on large stdout")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
