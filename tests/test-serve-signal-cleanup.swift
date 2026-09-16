#!/usr/bin/env swift
import Foundation

// Regression: mise run serve must not leave a detached Jekyll container when
// the Swift process dies on Ctrl-C.  defer does not run on SIGINT, so the
// script needs a named container and/or an explicit signal stop path.

struct TestError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }

    init(_ message: String) {
        self.message = message
    }
}

let scriptURL = URL(fileURLWithPath: #filePath).standardizedFileURL
let root = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let servePath = root.appendingPathComponent("scripts/serve.swift")

do {
    let source = try String(contentsOf: servePath, encoding: .utf8)

    guard source.contains("learnings-serve") else {
        throw TestError("\(servePath.path) must use a fixed container name (learnings-serve)")
    }
    guard source.contains("--name") else {
        throw TestError("\(servePath.path) must pass --name to docker run")
    }
    guard source.contains("rm") && source.contains("-f") else {
        throw TestError("\(servePath.path) must remove any leftover container before docker run")
    }

    // Signal delivery must stop the container; defer alone is not enough.
    let hasDispatchSignal = source.contains("makeSignalSource")
    let hasPosixSignal = source.contains("signal(SIGINT") || source.contains("SIG_IGN")
    guard hasDispatchSignal || hasPosixSignal else {
        throw TestError("\(servePath.path) must install a SIGINT/SIGTERM stop handler")
    }

    print("ok: serve.swift names the container and stops it on signal")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
