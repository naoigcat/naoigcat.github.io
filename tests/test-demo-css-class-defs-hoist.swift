#!/usr/bin/env swift
import Foundation

// Regression: demo CSS class scanning must enumerate _posts once, not once
// per watched class name.

typealias TestError = ScriptError

let root = repositoryRoot()
let testPath = root.appendingPathComponent("tests/test-demo-css-class-defs.swift")

do {
    let source = try String(contentsOf: testPath, encoding: .utf8)
    guard let loop = source.range(of: "for className in watched") else {
        throw TestError("\(testPath.path) is missing the watched loop")
    }
    let before = source[..<loop.lowerBound]
    let after = source[loop.lowerBound...]
    guard before.contains("markdownFiles(under: postsDirectory)") else {
        throw TestError("\(testPath.path) must call markdownFiles before the watched loop")
    }
    // The loop body must not re-enumerate posts.
    let body: String
    if let loopEnd = after.range(of: "guard errors.isEmpty") {
        body = String(after[..<loopEnd.lowerBound])
    } else {
        throw TestError("\(testPath.path): could not bound the watched loop")
    }
    if body.contains("markdownFiles(under:") {
        throw TestError("\(testPath.path) still calls markdownFiles inside the watched loop")
    }
    print("ok: test-demo-css-class-defs enumerates posts once")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
