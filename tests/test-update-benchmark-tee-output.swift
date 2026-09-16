#!/usr/bin/env swift
import Foundation

// Regression: runAndTee must create the output file before opening it.
// FileHandle(forWritingAtPath:) returns nil when the path does not exist,
// so a fresh temporary path would abort the benchmark before it starts.

struct TestError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }

    init(_ message: String) {
        self.message = message
    }
}

let scriptURL = URL(fileURLWithPath: #filePath).standardizedFileURL
let root = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let updateScript = root.appendingPathComponent(
    ".agents/skills/benchmark-sort/scripts/update-benchmark.swift"
)

do {
    let source = try String(contentsOf: updateScript, encoding: .utf8)
    guard let teeRange = source.range(of: "func runAndTee(") else {
        throw TestError("\(updateScript.path) is missing runAndTee")
    }
    let afterTee = source[teeRange.lowerBound...]
    guard let nextFunc = afterTee.range(of: "\nfunc ", options: [], range: afterTee.index(after: teeRange.lowerBound)..<afterTee.endIndex) else {
        throw TestError("\(updateScript.path): could not bound runAndTee")
    }
    let teeBody = String(afterTee[..<nextFunc.lowerBound])

    // Strip line comments so a doc note mentioning FileHandle cannot
    // satisfy or invert the create-before-open ordering check.
    let codeLines = teeBody
        .components(separatedBy: .newlines)
        .map { line -> String in
            if let slash = line.range(of: "//") {
                return String(line[..<slash.lowerBound])
            }
            return line
        }
        .joined(separator: "\n")

    // The helper must create the file; opening alone is not enough for a new path.
    guard codeLines.contains("createFile(atPath:") else {
        throw TestError("\(updateScript.path): runAndTee must createFile before opening the output path")
    }
    guard codeLines.contains("FileHandle(forWritingAtPath:") else {
        throw TestError("\(updateScript.path): runAndTee must open the output with FileHandle(forWritingAtPath:)")
    }
    let createIdx = codeLines.range(of: "createFile(atPath:")!.lowerBound
    let openIdx = codeLines.range(of: "FileHandle(forWritingAtPath:")!.lowerBound
    guard createIdx < openIdx else {
        throw TestError("\(updateScript.path): createFile must appear before FileHandle(forWritingAtPath:)")
    }

    // Document the Foundation behavior this fix depends on, so a future
    // platform change that starts creating missing files is noticed.
    let probeDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("tee-output-probe-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: probeDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: probeDirectory) }
    let missing = probeDirectory.appendingPathComponent("missing.txt")
    if FileHandle(forWritingAtPath: missing.path) != nil {
        throw TestError("FileHandle(forWritingAtPath:) unexpectedly created \(missing.path)")
    }
    guard FileManager.default.createFile(atPath: missing.path, contents: nil),
          FileHandle(forWritingAtPath: missing.path) != nil else {
        throw TestError("createFile + FileHandle(forWritingAtPath:) failed for \(missing.path)")
    }

    print("ok: runAndTee creates the benchmark output file before opening it")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
