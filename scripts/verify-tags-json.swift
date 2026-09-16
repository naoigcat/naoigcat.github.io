#!/usr/bin/env swift
import Foundation

// CI entry point for the generated tag metadata check.  Generation is kept in
// generate-tags-json.swift so local development and CI use the exact same
// Docker/Jekyll export path.

struct CommandResult {
    let status: Int32
}

struct ScriptError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }

    init(_ message: String) {
        self.message = message
    }
}

func runInherited(_ executable: String, _ arguments: [String], currentDirectory: URL) throws -> CommandResult {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [executable] + arguments
    process.currentDirectoryURL = currentDirectory
    process.standardInput = FileHandle.standardInput
    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError
    do {
        try process.run()
    } catch {
        throw ScriptError("Could not start \(executable): \(error)")
    }
    process.waitUntilExit()
    return CommandResult(status: process.terminationStatus)
}

func runStatus(_ executable: String, _ arguments: [String], currentDirectory: URL) throws -> Int32 {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [executable] + arguments
    process.currentDirectoryURL = currentDirectory
    let output = Pipe()
    let errors = Pipe()
    process.standardOutput = output
    process.standardError = errors
    do {
        try process.run()
    } catch {
        throw ScriptError("Could not start \(executable): \(error)")
    }
    process.waitUntilExit()
    return process.terminationStatus
}

let scriptURL = URL(fileURLWithPath: #filePath).standardizedFileURL
let root = scriptURL.deletingLastPathComponent().deletingLastPathComponent()

do {
    let generator = root.appendingPathComponent("scripts/generate-tags-json.swift")
    let generateStatus = try runInherited("swift", [generator.path], currentDirectory: root).status
    guard generateStatus == 0 else {
        throw ScriptError("Tag JSON generation failed with exit status \(generateStatus)")
    }

    // Intent-to-add makes newly generated files visible to git diff, matching
    // the behavior of the previous CI shell step without shell expansion.
    let addStatus = try runStatus(
        "git",
        ["add", "--intent-to-add", "assets/tags/"],
        currentDirectory: root
    )
    guard addStatus == 0 else {
        throw ScriptError("Could not stage assets/tags/ for comparison")
    }

    let diffStatus = try runInherited(
        "git",
        ["diff", "--exit-code", "--", "assets/tags/"],
        currentDirectory: root
    ).status
    if diffStatus != 0 {
        fputs("::error::assets/tags/ is out of date. Run: mise run tags\n", stderr)
        _ = try runInherited("git", ["diff", "--stat", "--", "assets/tags/"], currentDirectory: root)
        exit(1)
    }
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
