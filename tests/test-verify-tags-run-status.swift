#!/usr/bin/env swift
import Foundation

// Regression: status-only helpers must discard both streams with nullDevice
// (never attach unread pipes), and verify-tags-json must use that helper.

typealias TestError = ScriptError

let root = repositoryRoot()

do {
    let support = try String(
        contentsOf: root.appendingPathComponent("scripts/support.swift"),
        encoding: .utf8
    )
    guard let range = support.range(of: "func runStatus(") else {
        throw TestError("scripts/support.swift is missing runStatus")
    }
    let after = support[range.lowerBound...]
    let end = after.range(
        of: "\nfunc ",
        range: after.index(after: range.lowerBound)..<after.endIndex
    )?.lowerBound ?? after.endIndex
    let body = String(after[..<end])
    guard body.contains("FileHandle.nullDevice") else {
        throw TestError("runStatus must discard output with FileHandle.nullDevice")
    }
    guard !body.contains("Pipe()") else {
        throw TestError("runStatus must not attach unread pipes")
    }

    let verify = try String(
        contentsOf: root.appendingPathComponent("scripts/verify-tags-json.swift"),
        encoding: .utf8
    )
    guard verify.contains("runStatus(") else {
        throw TestError("verify-tags-json.swift must call runStatus")
    }
    guard !verify.contains("func runStatus("),
          !verify.contains("struct CommandResult") else {
        throw TestError("verify-tags-json.swift must not redefine runStatus/CommandResult")
    }

    print("ok: verify-tags-json uses shared runStatus with nullDevice")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
