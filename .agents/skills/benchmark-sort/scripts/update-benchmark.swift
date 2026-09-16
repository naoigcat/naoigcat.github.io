#!/usr/bin/env swift
import Foundation

// Re-measures one published sort table, or lists all benchmarkable targets.
// The workflow keeps argument parsing, post editing, and process orchestration
// in Swift so no shell wrapper is needed.

let excludedAlgorithms: Set<String> = ["bogo", "bozo"]

/// Streams a benchmark's stdout both to the terminal and to a file.
///
/// Benchmark output is intentionally visible while it runs.  Reading the pipe
/// incrementally avoids buffering a long run in memory and acts as the Swift
/// equivalent of the old shell tee command.
func runAndTee(
    _ executable: String,
    _ arguments: [String],
    currentDirectory: URL,
    outputFile: URL
) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [executable] + arguments
    process.currentDirectoryURL = currentDirectory
    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = FileHandle.standardError

    // FileHandle(forWritingAtPath:) does not create missing files; the temp
    // output path is new each run, so create it before opening for writing.
    guard FileManager.default.createFile(atPath: outputFile.path, contents: nil),
          let savedOutput = FileHandle(forWritingAtPath: outputFile.path) else {
        throw ScriptError("Could not open benchmark output: \(outputFile.path)")
    }
    do {
        try process.run()
    } catch {
        try? savedOutput.close()
        throw ScriptError("Could not start \(executable): \(error)")
    }

    // The generated program prints a small table, but chunked reads also keep
    // this helper safe if the benchmark ever gains progress diagnostics.
    while true {
        let data = outputPipe.fileHandleForReading.readData(ofLength: 64 * 1024)
        if data.isEmpty { break }
        FileHandle.standardOutput.write(data)
        savedOutput.write(data)
    }
    process.waitUntilExit()
    try? savedOutput.close()

    guard process.terminationStatus == 0 else {
        throw ScriptError("Benchmark failed with exit status \(process.terminationStatus)")
    }
}

func markdownFiles(under directory: URL) -> [URL] {
    (FileManager.default.enumerator(
        at: directory,
        includingPropertiesForKeys: [.isRegularFileKey]
    )?.allObjects ?? [])
        .compactMap { $0 as? URL }
        .filter { $0.pathExtension == "md" }
        .sorted { $0.path < $1.path }
}

func yamlAlgorithmKeys(from path: URL) throws -> Set<String> {
    let text = try String(contentsOf: path, encoding: .utf8)
    var keys = Set<String>()
    for line in text.components(separatedBy: .newlines) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let colon = trimmed.firstIndex(of: ":") else { continue }
        let key = String(trimmed[..<colon])
        if !key.isEmpty && key.allSatisfy({ $0.isLowercase || $0.isNumber || $0 == "_" }) {
            keys.insert(key)
        }
    }
    return keys
}

func normalizedSlug(_ input: String) -> String {
    let withoutPrefix = input.hasPrefix("sort-") ? String(input.dropFirst(5)) : input
    return withoutPrefix.replacingOccurrences(of: "-", with: "_")
}

func rejectExcluded(_ input: String) throws {
    let candidate = normalizedSlug(input)
    for excluded in excludedAlgorithms where input == excluded || candidate == excluded {
        throw ScriptError("Algorithm \"\(excluded)\" is excluded from benchmark recalculation.")
    }
}

func algorithmFromPost(_ text: String) -> String? {
    let pattern = #"sort-benchmark\.md algorithm="([^"]+)""#
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(
              in: text,
              range: NSRange(text.startIndex..<text.endIndex, in: text)
          ),
          let range = Range(match.range(at: 1), in: text) else {
        return nil
    }
    return String(text[range])
}

func resolveAlgorithm(_ input: String, root: URL) throws -> String {
    let yamlPath = root.appendingPathComponent("_data/sort_algorithms.yml")
    let keys = try yamlAlgorithmKeys(from: yamlPath)
    if keys.contains(input) { return input }

    let slug = normalizedSlug(input)
    if keys.contains(slug) { return slug }

    // A post filename fragment is resolved against the path, not arbitrary
    // prose, so an algorithm name mentioned in an article cannot be mistaken
    // for the requested post.
    for path in markdownFiles(under: root.appendingPathComponent("_posts"))
        where path.path.contains(input) {
        let text = try String(contentsOf: path, encoding: .utf8)
        if let algorithm = algorithmFromPost(text) {
            return algorithm
        }
    }
    throw ScriptError("Unknown algorithm or post slug: \(input)")
}

func listTargets(root: URL) throws -> [String] {
    var targets = Set<String>()
    for path in markdownFiles(under: root.appendingPathComponent("_posts")) {
        let text = try String(contentsOf: path, encoding: .utf8)
        if let algorithm = algorithmFromPost(text), !excludedAlgorithms.contains(algorithm) {
            targets.insert(algorithm)
        }
    }
    return targets.sorted()
}

func updatePost(_ post: URL, with benchmarkOutput: String) throws -> Int {
    let rowRegex = try NSRegularExpression(pattern: #"^\|\s+\d"#, options: [.anchorsMatchLines])
    let rows = benchmarkOutput.components(separatedBy: .newlines).filter { line in
        rowRegex.firstMatch(
            in: line,
            range: NSRange(line.startIndex..<line.endIndex, in: line)
        ) != nil
    }
    guard !rows.isEmpty else {
        throw ScriptError("Benchmark output contained no data rows")
    }

    let text = try String(contentsOf: post, encoding: .utf8)
    let startMarker = "<!-- sort-benchmark-result:start -->"
    let endMarker = "<!-- sort-benchmark-result:end -->"
    guard let start = text.range(of: startMarker),
          let end = text.range(of: endMarker, range: start.upperBound..<text.endIndex),
          end.lowerBound > start.upperBound else {
        throw ScriptError("Missing benchmark result markers in \(post.path)")
    }

    let header = [
        "|       Size | Average time (s) | Maximum time (s) | Average memory (KiB) | Maximum memory (KiB) |",
        "|-----------:|-----------------:|-----------------:|---------------------:|---------------------:|",
    ]
    let block = ([startMarker, ""] + header + rows + ["", endMarker]).joined(separator: "\n")
    let updated = String(text[..<start.lowerBound]) + block + String(text[end.upperBound...])
    try updated.write(to: post, atomically: true, encoding: .utf8)
    return rows.count
}

let arguments = scriptArguments()
let root = repositoryRoot()
let support = root.appendingPathComponent("scripts/support.swift")
let swiftRun = root.appendingPathComponent("scripts/swift-run.swift")

do {
    if arguments == ["--list-targets"] {
        for target in try listTargets(root: root) {
            print(target)
        }
        exit(0)
    }
    guard !arguments.isEmpty, arguments.count <= 2 else {
        throw ScriptError(
            "usage: update-benchmark.swift <algorithm> [--dry-run]\n" +
            "       update-benchmark.swift --list-targets"
        )
    }
    let input = arguments[0]
    let dryRun = arguments.count == 2 && arguments[1] == "--dry-run"
    if arguments.count == 2 && !dryRun {
        throw ScriptError(
            "usage: update-benchmark.swift <algorithm> [--dry-run]\n" +
            "       update-benchmark.swift --list-targets"
        )
    }
    try rejectExcluded(input)

    let algorithm = try resolveAlgorithm(input, root: root)
    if excludedAlgorithms.contains(algorithm) {
        throw ScriptError("Algorithm \"\(algorithm)\" is excluded from benchmark recalculation.")
    }

    let includeNeedle = "sort-benchmark.md algorithm=\"\(algorithm)\""
    let posts = try markdownFiles(under: root.appendingPathComponent("_posts")).filter { path in
        try String(contentsOf: path, encoding: .utf8).contains(includeNeedle)
    }
    guard !posts.isEmpty else {
        throw ScriptError("No post includes \(includeNeedle)")
    }
    guard posts.count == 1 else {
        let names = posts.map { "  \($0.path)" }.joined(separator: "\n")
        throw ScriptError("Multiple posts reference algorithm=\"\(algorithm)\":\n\(names)")
    }
    let post = posts[0]
    let relativePost = post.path.replacingOccurrences(of: root.path + "/", with: "")
    fputs("algorithm: \(algorithm)\npost:      \(relativePost)\n", stderr)

    let renderScript = root.appendingPathComponent(
        ".agents/skills/benchmark-sort/scripts/render-benchmark-script.swift"
    )
    let rendered = try requireCommand(
        "swift",
        [swiftRun.path, renderScript.path, support.path, algorithm],
        currentDirectory: root
    )

    if dryRun {
        fputs("Dry run OK (benchmark Swift program renders).\n", stderr)
        exit(0)
    }

    try requireCommand("docker", ["info"], currentDirectory: root, discardStdout: true)
    let temporaryDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("sort-benchmark-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
    let benchmarkSource = temporaryDirectory.appendingPathComponent("benchmark.swift")
    let benchmarkOutput = temporaryDirectory.appendingPathComponent("benchmark-output.txt")
    try rendered.stdout.write(to: benchmarkSource, atomically: true, encoding: .utf8)

    fputs("Running benchmark (this may take 10–30+ minutes)…\n", stderr)
    try runAndTee(
        "swift",
        [benchmarkSource.path],
        currentDirectory: root,
        outputFile: benchmarkOutput
    )
    let output = try String(contentsOf: benchmarkOutput, encoding: .utf8)
    let rowCount = try updatePost(post, with: output)
    fputs("Updated \(post.path) (\(rowCount) rows)\n", stderr)

    fputs("Running markdownlint…\n", stderr)
    try runInherited(
        "mise",
        ["run", "lint", "--", relativePost],
        currentDirectory: root
    )
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
