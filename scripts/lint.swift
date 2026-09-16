#!/usr/bin/env swift
import Foundation

// This is the Swift entry point for `mise run lint`.  It deliberately passes
// Docker arguments as an array instead of assembling a shell command, so a
// Markdown path containing spaces or punctuation remains one path argument.
// The default glob and --fix flag are parsed here rather than delegated to
// mise, keeping `.mise.toml` as a thin task dispatcher.

func projectConfigValue(_ key: String, root: URL) throws -> String {
    // Swift scripts are intentionally standalone, so the shared constants
    // are exposed through config.swift's small CLI instead of a package import.
    let config = root.appendingPathComponent("scripts/config.swift")
    let result = try requireCommand(
        "swift",
        [config.path, key],
        currentDirectory: root
    )
    let value = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty else {
        throw ScriptError("config.swift returned an empty value for \(key)")
    }
    return value
}

let root = repositoryRoot()

do {
    let image = try projectConfigValue("markdownlint-cli2-image", root: root)

    // Task arguments are parsed here for both `mise` and direct Swift
    // invocations, keeping the two entry points behaviorally identical.
    var arguments = scriptArguments()
    if arguments.first == "--" {
        arguments.removeFirst()
    }
    // Both mise task arguments and direct Swift invocations arrive here as
    // ordinary arguments.  There is no hidden environment flag.
    let fix = arguments.contains("--fix")
    arguments.removeAll { $0 == "--fix" }
    if arguments.isEmpty {
        arguments = ["**/*.md"]
    }

    let uid = try requireCommand("id", ["-u"]).stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    let gid = try requireCommand("id", ["-g"]).stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !uid.isEmpty, !gid.isEmpty else {
        throw ScriptError("Failed to resolve uid:gid")
    }

    var dockerArguments = [
        "run", "--rm",
        "--user", "\(uid):\(gid)",
        "--volume", "\(root.path):/workdir",
        "--workdir", "/workdir",
        image,
    ]
    dockerArguments.append(contentsOf: ["--config", ".markdownlint-cli2.jsonc"])
    if fix {
        dockerArguments.append("--fix")
    }
    dockerArguments.append(contentsOf: arguments)

    // Markdownlint output is user-facing, so inherit it directly rather than
    // buffering it.  The command still has no shell layer around it.
    let status = try runCommand(
        "docker",
        dockerArguments,
        currentDirectory: root,
        inheritIO: true
    ).status
    guard status == 0 else {
        exit(status)
    }
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
