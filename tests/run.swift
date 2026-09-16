#!/usr/bin/env swift
import Foundation

// Test discovery remains filename-based, just like the old `find | sort`
// runner.  The important difference is that every repository test is now a
// Swift program (with the existing JavaScript fixture retained as Node code),
// so Bash is no longer needed to orchestrate the suite.

func writeLine(_ line: String) {
    // FileHandle writes immediately, so the discovery header appears before
    // the child test's output even when mise captures the runner's stdout.
    let data = Data((line + "\n").utf8)
    FileHandle.standardOutput.write(data)
}

let root = repositoryRoot()
let testsDirectory = root.appendingPathComponent("tests")
let support = root.appendingPathComponent("scripts/support.swift")
let swiftRun = root.appendingPathComponent("scripts/swift-run.swift")

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
        throw ScriptError("No test scripts found under \(testsDirectory.path)")
    }

    var failed = false
    for testFile in testFiles {
        writeLine("==> \(testFile.lastPathComponent)")
        let result: CommandResult
        if testFile.pathExtension == "mjs" {
            result = try runCommand(
                "node",
                [testFile.path],
                currentDirectory: root,
                inheritIO: true
            )
        } else {
            // Inherit IO and tolerate non-zero so one failing test does not abort
            // the suite before the remaining files run.
            result = try runCommand(
                "swift",
                [swiftRun.path, testFile.path, support.path],
                currentDirectory: root,
                inheritIO: true
            )
        }
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
