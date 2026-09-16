#!/usr/bin/env swift
import Foundation

// This file is the single source of truth for values that used to live in
// `.mise.toml`.  Keeping the values in Swift means the task file only needs to
// dispatch to Swift programs, while scheduled maintenance can still update a
// normal, type-checked source file.
enum ProjectConfig {
    // The image contains the GitHub Pages Jekyll dependency set used by local
    // preview, tag export, and benchmark rendering.
    static let githubPagesImage = "naoigcat/github-pages:232"

    // The pinned CLI image keeps local linting reproducible and matches the
    // markdownlint action version synchronized by CI.
    static let markdownlintCLI2Image = "davidanson/markdownlint-cli2:v0.23.2"
}

struct ConfigError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }

    init(_ message: String) {
        self.message = message
    }
}

// The other standalone Swift scripts query this file through this tiny CLI.
// A CLI keeps one value authoritative without requiring a Swift package or a
// generated intermediate file just to share two Docker image references.
let arguments = Array(CommandLine.arguments.dropFirst())

do {
    guard arguments.count == 1 else {
        throw ConfigError(
            "usage: config.swift github-pages-image|markdownlint-cli2-image"
        )
    }

    switch arguments[0] {
    case "github-pages-image":
        print(ProjectConfig.githubPagesImage)
    case "markdownlint-cli2-image":
        print(ProjectConfig.markdownlintCLI2Image)
    default:
        throw ConfigError(
            "usage: config.swift github-pages-image|markdownlint-cli2-image"
        )
    }
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
