#!/usr/bin/env swift
import Foundation

// Regression: repository automation is written in Swift and site behavior is
// written in JavaScript.  Parse both sets directly so a typo is caught before
// a mise task or a browser loads it.

struct CommandResult {
    let status: Int32
    let output: String
}

struct TestError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }

    init(_ message: String) {
        self.message = message
    }
}

func runCommand(_ executable: String, _ arguments: [String], currentDirectory: URL) throws -> CommandResult {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [executable] + arguments
    process.currentDirectoryURL = currentDirectory

    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = outputPipe
    do {
        try process.run()
    } catch {
        throw TestError("Could not start \(executable): \(error)")
    }
    process.waitUntilExit()
    let output = String(
        data: outputPipe.fileHandleForReading.readDataToEndOfFile(),
        encoding: .utf8
    ) ?? ""
    return CommandResult(status: process.terminationStatus, output: output)
}

func regularFiles(under directory: URL, fileExtension: String) -> [URL] {
    (FileManager.default.enumerator(
        at: directory,
        includingPropertiesForKeys: [.isRegularFileKey]
    )?.allObjects ?? [])
        .compactMap { $0 as? URL }
        .filter { $0.pathExtension == fileExtension }
        .sorted { $0.path < $1.path }
}

let scriptURL = URL(fileURLWithPath: #filePath).standardizedFileURL
let root = scriptURL.deletingLastPathComponent().deletingLastPathComponent()

do {
    let swiftScriptDirectories = [
        root.appendingPathComponent("scripts"),
        root.appendingPathComponent("tests"),
        root.appendingPathComponent(".agents/skills/benchmark-sort/scripts"),
    ]

    // Leaving a shell file in one of these automation directories would make
    // the migration incomplete, even if the current mise task no longer calls
    // it.  The test is deliberately scoped away from educational snippets in
    // posts and README files.
    let shellFiles = swiftScriptDirectories.flatMap { directory in
        regularFiles(under: directory, fileExtension: "sh")
    }
    if !shellFiles.isEmpty {
        let names = shellFiles.map { $0.path.replacingOccurrences(of: root.path + "/", with: "") }
        throw TestError("shell scripts remain in automation directories:\n\(names.joined(separator: "\n"))")
    }

    var failures: [String] = []
    for directory in swiftScriptDirectories {
        for path in regularFiles(under: directory, fileExtension: "swift") {
            let result = try runCommand("swiftc", ["-parse", path.path], currentDirectory: root)
            if result.status != 0 {
                failures.append("swiftc -parse failed: \(path.path)\n\(result.output)")
            }
        }
    }

    for path in regularFiles(under: root.appendingPathComponent("assets/js"), fileExtension: "js") {
        let result = try runCommand("node", ["--check", path.path], currentDirectory: root)
        if result.status != 0 {
            failures.append("node --check failed: \(path.path)\n\(result.output)")
        }
    }

    guard failures.isEmpty else {
        fputs(failures.joined(separator: "\n"), stderr)
        exit(1)
    }
    print("ok: Swift and JS syntax")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
