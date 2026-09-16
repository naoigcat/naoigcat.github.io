#!/usr/bin/env swift
import Foundation

// CI entry point for the generated tag metadata check.  Generation is kept in
// generate-tags-json.swift so local development and CI use the exact same
// Docker/Jekyll export path.

let root = repositoryRoot()
let support = root.appendingPathComponent("scripts/support.swift")
let swiftRun = root.appendingPathComponent("scripts/swift-run.swift")

do {
    let generator = root.appendingPathComponent("scripts/generate-tags-json.swift")
    try runInherited(
        "swift",
        [swiftRun.path, generator.path, support.path],
        currentDirectory: root
    )

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

    // Non-zero from --exit-code means the tree differs; do not use runInherited
    // here because that helper treats any non-zero status as failure.
    let diffStatus = try runCommand(
        "git",
        ["diff", "--exit-code", "--", "assets/tags/"],
        currentDirectory: root,
        inheritIO: true
    ).status
    if diffStatus != 0 {
        fputs("::error::assets/tags/ is out of date. Run: mise run tags\n", stderr)
        _ = try runCommand(
            "git",
            ["diff", "--stat", "--", "assets/tags/"],
            currentDirectory: root,
            inheritIO: true
        )
        exit(1)
    }
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
