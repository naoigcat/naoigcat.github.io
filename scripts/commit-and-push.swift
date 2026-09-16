#!/usr/bin/env swift
import Foundation

// Shared GitHub Actions commit step.  It intentionally handles only the
// narrow path that a workflow has just updated, just as the former shell
// blocks did, then pushes the resulting commit.

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
    currentDirectory: URL,
    inheritIO: Bool = false
) throws -> CommandResult {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [executable] + arguments
    process.currentDirectoryURL = currentDirectory
    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    if inheritIO {
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError
    } else {
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
    }
    do {
        try process.run()
    } catch {
        throw ScriptError("Could not start \(executable): \(error)")
    }
    process.waitUntilExit()
    guard !inheritIO else {
        return CommandResult(status: process.terminationStatus, stdout: "", stderr: "")
    }
    return CommandResult(
        status: process.terminationStatus,
        stdout: String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "",
        stderr: String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    )
}

func pagesTag(from config: String) -> String? {
    // The scheduled image-sync job updates the Swift configuration rather
    // than TOML, so derive the commit message from the same source file.
    for line in config.split(separator: "\n", omittingEmptySubsequences: false) {
        let raw = String(line)
        guard let equals = raw.firstIndex(of: "="),
              raw[..<equals].trimmingCharacters(in: .whitespaces)
                == "static let githubPagesImage" else {
            continue
        }
        let value = raw[raw.index(after: equals)...].trimmingCharacters(in: .whitespaces)
        guard value.first == "\"" else { continue }
        let payload = value.dropFirst()
        guard let end = payload.firstIndex(of: "\"") else { continue }
        let image = String(payload[..<end])
        guard let colon = image.lastIndex(of: ":") else { return nil }
        return String(image[image.index(after: colon)...])
    }
    return nil
}

let scriptURL = URL(fileURLWithPath: #filePath).standardizedFileURL
let root = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let arguments = Array(CommandLine.arguments.dropFirst())

do {
    let path: String
    let message: String
    if arguments == ["--github-pages-image"] {
        path = "scripts/config.swift"
        let configPath = root.appendingPathComponent(path)
        let config = try String(contentsOf: configPath, encoding: .utf8)
        guard let tag = pagesTag(from: config),
              tag.range(of: #"^[0-9]+$"#, options: .regularExpression) != nil else {
            throw ScriptError("Could not parse numeric Docker tag after bump.")
        }
        message = "Bump ProjectConfig.githubPagesImage to Docker Hub tag \(tag)"
    } else if arguments.isEmpty,
              let environmentPath = ProcessInfo.processInfo.environment["COMMIT_PATH"],
              let environmentMessage = ProcessInfo.processInfo.environment["COMMIT_MESSAGE"],
              !environmentPath.isEmpty,
              !environmentMessage.isEmpty {
        path = environmentPath
        message = environmentMessage
    } else {
        throw ScriptError(
            "usage: commit-and-push.swift --github-pages-image\n" +
            "       COMMIT_PATH=... COMMIT_MESSAGE=... commit-and-push.swift"
        )
    }

    let configuredName = try runCommand(
        "git",
        ["config", "user.name", "github-actions[bot]"],
        currentDirectory: root,
        inheritIO: true
    )
    guard configuredName.status == 0 else {
        throw ScriptError("git config user.name failed with exit status \(configuredName.status)")
    }
    let configuredEmail = try runCommand(
        "git",
        ["config", "user.email", "41898282+github-actions[bot]@users.noreply.github.com"],
        currentDirectory: root,
        inheritIO: true
    )
    guard configuredEmail.status == 0 else {
        throw ScriptError("git config user.email failed with exit status \(configuredEmail.status)")
    }
    let add = try runCommand("git", ["add", path], currentDirectory: root)
    guard add.status == 0 else {
        throw ScriptError(add.stderr.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // git diff --quiet returns 0 when no staged change and 1 when a change is
    // present.  Treating only those two statuses specially preserves the
    // former shell branch while still surfacing real git errors.
    let staged = try runCommand(
        "git",
        ["diff", "--cached", "--quiet"],
        currentDirectory: root
    )
    if staged.status == 0 {
        print("No change to commit.")
        exit(0)
    }
    guard staged.status == 1 else {
        throw ScriptError(staged.stderr.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    let commit = try runCommand("git", ["commit", "-m", message], currentDirectory: root, inheritIO: true)
    guard commit.status == 0 else {
        throw ScriptError("git commit failed with exit status \(commit.status)")
    }
    let push = try runCommand("git", ["push"], currentDirectory: root, inheritIO: true)
    guard push.status == 0 else {
        throw ScriptError("git push failed with exit status \(push.status)")
    }
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
