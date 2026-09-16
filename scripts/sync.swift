#!/usr/bin/env swift
import Foundation

// Shared maintenance entry point for the repository's pinned Docker images.
// The workflow keeps the individual operations as subcommands so GitHub
// outputs and failure boundaries remain explicit while the implementation has
// one source file.

struct CommandResult {
    let status: Int32
    let stdout: Data
    let stderr: Data

    var stdoutText: String {
        String(data: stdout, encoding: .utf8) ?? ""
    }

    var stderrText: String {
        String(data: stderr, encoding: .utf8) ?? ""
    }
}

struct ScriptError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }

    init(_ message: String) {
        self.message = message
    }
}

struct DockerImageReference {
    let displayRepository: String
    let hubSlug: String
    let currentTag: String
}

func runCommand(_ executable: String, _ arguments: [String], currentDirectory: URL) throws -> CommandResult {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [executable] + arguments
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
    return CommandResult(
        status: process.terminationStatus,
        stdout: stdoutPipe.fileHandleForReading.readDataToEndOfFile(),
        stderr: stderrPipe.fileHandleForReading.readDataToEndOfFile()
    )
}

func repositoryRoot() -> URL {
    let scriptURL = URL(fileURLWithPath: #filePath).standardizedFileURL
    let sourceRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
    return URL(
        fileURLWithPath: ProcessInfo.processInfo.environment["GITHUB_WORKSPACE"] ?? sourceRoot.path
    ).standardizedFileURL
}

func isASCIIInteger(_ value: String) -> Bool {
    !value.isEmpty && value.unicodeScalars.allSatisfy { scalar in
        scalar.value >= 48 && scalar.value <= 57
    }
}

func parseImageReference(from text: String) throws -> DockerImageReference {
    let linePattern = #"^\s*static\s+let\s+githubPagesImage\s*=\s*"([^"]+)"\s*$"#
    let regex = try NSRegularExpression(pattern: linePattern)
    let assignment = text.components(separatedBy: .newlines).first { line in
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        return regex.firstMatch(in: line, range: range) != nil
    }
    guard let assignment else {
        throw ScriptError("Missing githubPagesImage in scripts/config.swift")
    }
    let range = NSRange(assignment.startIndex..<assignment.endIndex, in: assignment)
    guard let match = regex.firstMatch(in: assignment, range: range),
          let valueRange = Range(match.range(at: 1), in: assignment) else {
        throw ScriptError("Could not parse githubPagesImage line: \(assignment)")
    }
    let payload = String(assignment[valueRange]).trimmingCharacters(in: .whitespaces)
    guard let colon = payload.lastIndex(of: ":") else {
        throw ScriptError("githubPagesImage must include a ':tag'; got \(payload.debugDescription)")
    }

    let repository = String(payload[..<colon]).trimmingCharacters(in: .whitespaces)
    let currentTag = String(payload[payload.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
    let lowered = repository.lowercased()
    for blocked in ["ghcr.io/", "docker.pkg.github.com/"] where lowered.hasPrefix(blocked) {
        throw ScriptError(
            "Docker Hub polls only; unsupported registry hint in \(repository.debugDescription)"
        )
    }

    let hubPrefix = "docker.io/"
    let hubSlug = lowered.hasPrefix(hubPrefix)
        ? String(repository.dropFirst(hubPrefix.count))
        : repository
    let segments = hubSlug.split(separator: "/", omittingEmptySubsequences: false)
    guard segments.count == 2, segments.allSatisfy({ !$0.isEmpty }) else {
        throw ScriptError(
            "Expected '<namespace>/<name>:tag'; got \(hubSlug.debugDescription) " +
            "with tag \(currentTag.debugDescription)"
        )
    }
    return DockerImageReference(
        displayRepository: repository,
        hubSlug: hubSlug,
        currentTag: currentTag
    )
}

func numericTagsFromDockerHub(slug: String, root: URL) throws -> Set<Int> {
    var url = "https://hub.docker.com/v2/repositories/\(slug)/tags?page_size=100"
    var collected = Set<Int>()

    while !url.isEmpty {
        let result = try runCommand(
            "curl",
            ["-fsSL", "--max-time", "90", url],
            currentDirectory: root
        )
        guard result.status == 0 else {
            let detail = result.stderrText.trimmingCharacters(in: .whitespacesAndNewlines)
            throw ScriptError("Docker Hub fetch failed (\(url)): \(detail)")
        }

        let body: Any
        do {
            body = try JSONSerialization.jsonObject(with: result.stdout, options: [.fragmentsAllowed])
        } catch {
            throw ScriptError("Invalid Docker Hub JSON: \(error)")
        }
        guard let object = body as? [String: Any] else {
            throw ScriptError("Invalid Docker Hub JSON: root is not an object")
        }
        if let results = object["results"] as? [Any] {
            for item in results {
                guard let tag = item as? [String: Any],
                      let name = tag["name"] as? String,
                      isASCIIInteger(name),
                      let number = Int(name) else {
                    continue
                }
                collected.insert(number)
            }
        }
        url = object["next"] as? String ?? ""
    }
    return collected
}

func rewriteAssignment(
    in text: String,
    key: String,
    replacement: String
) throws -> String {
    var lines = text.components(separatedBy: "\n")
    var matched = false

    for index in lines.indices {
        var line = lines[index]
        var lineEnding = ""
        if line.hasSuffix("\r") {
            line.removeLast()
            lineEnding = "\r\n"
        } else if index < lines.index(before: lines.endIndex) {
            lineEnding = "\n"
        }
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if !matched && trimmed.hasPrefix("static let \(key)") {
            lines[index] = replacement + lineEnding
            matched = true
        } else {
            lines[index] = line + lineEnding
        }
    }
    guard matched else {
        throw ScriptError("\(key) assignment not found during rewrite")
    }
    return lines.joined()
}

func writeGitHubOutput(_ name: String, _ value: String) throws {
    // GitHub provides GITHUB_OUTPUT only inside Actions. Printing the pair
    // when absent keeps local dry checks useful without pretending to set an
    // output in the caller's environment.
    guard let outputPath = ProcessInfo.processInfo.environment["GITHUB_OUTPUT"],
          !outputPath.isEmpty else {
        print("\(name)=\(value)")
        return
    }
    let line = "\(name)=\(value)\n"
    guard let data = line.data(using: .utf8) else {
        throw ScriptError("Could not encode GitHub output \(name)")
    }
    let handle = try FileHandle(forWritingTo: URL(fileURLWithPath: outputPath))
    try handle.seekToEnd()
    try handle.write(contentsOf: data)
    try handle.close()
}

func syncGitHubPagesImage(root: URL) throws {
    let configPath = root.appendingPathComponent("scripts/config.swift")
    guard FileManager.default.isReadableFile(atPath: configPath.path) else {
        throw ScriptError("\(configPath.path) missing")
    }
    let text = try String(contentsOf: configPath, encoding: .utf8)
    let image = try parseImageReference(from: text)
    guard isASCIIInteger(image.currentTag) else {
        throw ScriptError(
            "Existing tag \(image.currentTag.debugDescription) is non-numeric; refusing automation"
        )
    }

    let tags = try numericTagsFromDockerHub(slug: image.hubSlug, root: root)
    guard let newest = tags.max() else {
        throw ScriptError("No purely numeric tags under Docker Hub repo \(image.hubSlug)")
    }
    guard let current = Int(image.currentTag) else {
        throw ScriptError(
            "Existing tag \(image.currentTag.debugDescription) is too large for Swift Int"
        )
    }

    if newest == current {
        print("githubPagesImage already at numeric tag \(newest); no Swift config rewrite.")
        return
    }
    if newest < current {
        print(
            "githubPagesImage is ahead of Docker Hub numeric tags " +
            "(\(current) > \(newest)); no Swift config rewrite."
        )
        return
    }

    let replacement = "    static let githubPagesImage = \"\(image.displayRepository):\(newest)\""
    let updated = try rewriteAssignment(
        in: text,
        key: "githubPagesImage",
        replacement: replacement
    )
    try updated.write(to: configPath, atomically: true, encoding: .utf8)
    print("Bumped githubPagesImage (\(image.displayRepository)) \(current) -> \(newest).")
}

func markdownlintActionRef(root: URL) throws -> String {
    let workflow = root.appendingPathComponent(".github/workflows/lint.yml")
    let text = try String(contentsOf: workflow, encoding: .utf8)
    let regex = try NSRegularExpression(
        pattern: #"(?i)uses:\s*DavidAnson/markdownlint-cli2-action@([^\s#]+)"#
    )
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    guard let match = regex.firstMatch(in: text, range: range),
          let refRange = Range(match.range(at: 1), in: text) else {
        throw ScriptError("Could not find DavidAnson/markdownlint-cli2-action in \(workflow.path)")
    }
    return String(text[refRange])
}

func markdownlintVersion(ref: String, root: URL) throws -> String {
    let url = "https://raw.githubusercontent.com/DavidAnson/markdownlint-cli2-action/\(ref)/package.json"
    print("Fetching \(url)")
    let package = try runCommand("curl", ["-fsSL", url], currentDirectory: root)
    guard package.status == 0 else {
        throw ScriptError("Could not fetch package.json: \(package.stderrText)")
    }

    let json: Any
    do {
        json = try JSONSerialization.jsonObject(with: package.stdout, options: [.fragmentsAllowed])
    } catch {
        throw ScriptError("Invalid action package.json: \(error)")
    }
    guard let object = json as? [String: Any],
          let dependencies = object["dependencies"] as? [String: Any],
          let version = dependencies["markdownlint-cli2"] as? String,
          !version.isEmpty else {
        throw ScriptError("Could not read dependencies.markdownlint-cli2 from action package.json")
    }
    return version
}

func updateMarkdownlintImage(root: URL, version: String) throws {
    let configPath = root.appendingPathComponent("scripts/config.swift")
    guard FileManager.default.isReadableFile(atPath: configPath.path) else {
        throw ScriptError("\(configPath.path) missing")
    }
    let text = try String(contentsOf: configPath, encoding: .utf8)
    let replacement = "    static let markdownlintCLI2Image = \"davidanson/markdownlint-cli2:v\(version)\""
    let updated = try rewriteAssignment(
        in: text,
        key: "markdownlintCLI2Image",
        replacement: replacement
    )
    try updated.write(to: configPath, atomically: true, encoding: .utf8)
    guard updated.contains(replacement) else {
        throw ScriptError("markdownlintCLI2Image assignment not found in \(configPath.path)")
    }
}

let root = repositoryRoot()
let arguments = Array(CommandLine.arguments.dropFirst())
let usage = "usage: sync.swift github-pages-image|markdownlint resolve-ref|fetch-version|update"

do {
    guard !arguments.isEmpty else {
        throw ScriptError(usage)
    }

    switch arguments[0] {
    case "github-pages-image":
        guard arguments.count == 1 else {
            throw ScriptError(usage)
        }
        try syncGitHubPagesImage(root: root)

    case "markdownlint":
        guard arguments.count == 2 else {
            throw ScriptError(usage)
        }
        switch arguments[1] {
        case "resolve-ref":
            let workflowRef = try markdownlintActionRef(root: root)
            print("Using action ref: \(workflowRef)")
            try writeGitHubOutput("ref", workflowRef)

        case "fetch-version":
            guard let ref = ProcessInfo.processInfo.environment["ACTION_REF"], !ref.isEmpty else {
                throw ScriptError("ACTION_REF is required")
            }
            let version = try markdownlintVersion(ref: ref, root: root)
            print("markdownlint-cli2=\(version)")
            try writeGitHubOutput("version", version)

        case "update":
            guard let version = ProcessInfo.processInfo.environment["VERSION"], !version.isEmpty else {
                throw ScriptError("VERSION is required")
            }
            try updateMarkdownlintImage(root: root, version: version)

        default:
            throw ScriptError(usage)
        }

    default:
        throw ScriptError(usage)
    }
} catch {
    fputs("::error::\(error)\n", stderr)
    exit(1)
}
