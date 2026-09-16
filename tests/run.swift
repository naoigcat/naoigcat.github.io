#!/usr/bin/env swift
import Foundation

// Test discovery remains filename-based, just like the old `find | sort`
// runner.  The important difference is that every repository test is now a
// Swift program (with the existing JavaScript fixture retained as Node code),
// so Bash is no longer needed to orchestrate the suite.

struct CommandResult {
    let status: Int32
}

struct RunnerError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }

    init(_ message: String) {
        self.message = message
    }
}

func runInherited(_ executable: String, _ arguments: [String], currentDirectory: URL) throws -> CommandResult {
    let process = Process()
    if executable.hasPrefix("/") {
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
    } else {
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [executable] + arguments
    }
    process.currentDirectoryURL = currentDirectory
    process.standardInput = FileHandle.standardInput
    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError

    do {
        try process.run()
    } catch {
        throw RunnerError("Could not start \(executable): \(error)")
    }
    process.waitUntilExit()
    return CommandResult(status: process.terminationStatus)
}

func writeLine(_ line: String) {
    // FileHandle writes immediately, so the discovery header appears before
    // the child test's output even when mise captures the runner's stdout.
    let data = Data((line + "\n").utf8)
    FileHandle.standardOutput.write(data)
}

let testsDirectory = URL(fileURLWithPath: #filePath)
    .standardizedFileURL
    .deletingLastPathComponent()
let root = testsDirectory.deletingLastPathComponent()

do {
    let entries = try FileManager.default.contentsOfDirectory(
        at: testsDirectory,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
    )
    let testFiles = entries
        .filter { url in
            let name = url.lastPathComponent
            return name.hasPrefix("test-") && (url.pathExtension == "swift" || url.pathExtension == "mjs")
        }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

    guard !testFiles.isEmpty else {
        throw RunnerError("No test scripts found under \(testsDirectory.path)")
    }

    var failed = false
    for testFile in testFiles {
        writeLine("==> \(testFile.lastPathComponent)")
        let interpreter = testFile.pathExtension == "mjs" ? "node" : "swift"
        let result = try runInherited(
            interpreter,
            [testFile.path],
            currentDirectory: root
        )
        if result.status != 0 {
            failed = true
        }
    }

    if failed {
        fputs("FAILED: one or more tests did not pass\n", stderr)
        exit(1)
    }
    writeLine("All \(testFiles.count) test(s) passed.")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
