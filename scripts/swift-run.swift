#!/usr/bin/env swift
import Foundation

// Concatenates companion sources into one temporary script and interprets it.
// Swift 6+ `swift main.swift support.swift` only interprets the first file;
// a single concatenated script keeps top-level `do` / `print` working.

struct DriverError: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
    init(_ message: String) { self.message = message }
}

func stripShebang(from source: String) -> String {
    var text = source
    if text.hasPrefix("#!"), let end = text.firstIndex(of: "\n") {
        text = String(text[text.index(after: end)...])
    }
    return text
}

/// Drops a leading `import Foundation` so concatenating files does not duplicate it.
func stripLeadingFoundationImport(from source: String) -> String {
    var text = source
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.hasPrefix("import Foundation") {
        if let end = text.range(of: "import Foundation") {
            text = String(text[end.upperBound...])
            if text.hasPrefix("\r\n") {
                text = String(text.dropFirst(2))
            } else if text.hasPrefix("\n") {
                text = String(text.dropFirst())
            }
        }
    }
    return text
}

let args = Array(CommandLine.arguments.dropFirst())
var sources: [String] = []
var rest: [String] = []
for arg in args {
    if rest.isEmpty && arg.hasSuffix(".swift") {
        sources.append(arg)
    } else {
        rest.append(arg)
    }
}

guard !sources.isEmpty else {
    fputs("usage: swift-run.swift <main.swift> [companion.swift ...] [args...]\n", stderr)
    exit(2)
}

do {
    // Companions (typically support.swift) first so their declarations are in
    // scope for the main script's top-level code.
    let mainPath = sources[0]
    let companions = Array(sources.dropFirst())
    var combined = ""
    for (index, path) in (companions + [mainPath]).enumerated() {
        var text = stripShebang(from: try String(contentsOfFile: path, encoding: .utf8))
        if index > 0 {
            text = stripLeadingFoundationImport(from: text)
        }
        combined += text
        if !combined.hasSuffix("\n") {
            combined += "\n"
        }
        combined += "\n"
    }

    let temporaryDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("swift-run-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

    let script = temporaryDirectory.appendingPathComponent("combined.swift")
    try combined.write(to: script, atomically: true, encoding: .utf8)

    // #filePath inside the combined temp script is useless for finding the
    // repo; point repositoryRoot() at the main script's tree instead.
    var repoRoot = URL(fileURLWithPath: mainPath).standardizedFileURL.deletingLastPathComponent()
    while true {
        if FileManager.default.fileExists(atPath: repoRoot.appendingPathComponent("_config.yml").path) {
            break
        }
        let parent = repoRoot.deletingLastPathComponent()
        if parent.path == repoRoot.path {
            break
        }
        repoRoot = parent
    }

    let run = Process()
    run.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    run.arguments = ["swift", script.path] + rest
    run.environment = ProcessInfo.processInfo.environment.merging([
        "LEARNINGS_REPO_ROOT": repoRoot.path,
    ]) { _, new in new }
    run.standardInput = FileHandle.standardInput
    run.standardOutput = FileHandle.standardOutput
    run.standardError = FileHandle.standardError
    try run.run()
    run.waitUntilExit()
    exit(run.terminationStatus)
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
