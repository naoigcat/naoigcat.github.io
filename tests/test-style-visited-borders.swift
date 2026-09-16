#!/usr/bin/env swift
import Foundation

// Regression: blockquote/pre/code border rules must not nest under a:visited,
// which would only match anchors containing those elements (none do).

typealias TestError = ScriptError

let root = repositoryRoot()
let scssPath = root.appendingPathComponent("_sass/style.scss")

do {
    let source = try String(contentsOf: scssPath, encoding: .utf8)
    guard let visited = source.range(of: "&:visited") else {
        // Visiting styles may be absent; the border rules must still exist.
        guard source.contains("blockquote") && source.contains("border: 1px solid #e8e8e8") else {
            throw TestError("\(scssPath.path) is missing blockquote/pre/code border rules")
        }
        print("ok: style.scss border rules are not nested under a:visited")
        exit(0)
    }
    // Find the visited block body and ensure it does not mention blockquote.
    let fromVisited = source[visited.lowerBound...]
    guard let open = fromVisited.firstIndex(of: "{") else {
        throw TestError("\(scssPath.path): could not parse &:visited block")
    }
    var depth = 0
    var i = open
    var end = open
    while i < fromVisited.endIndex {
        let ch = fromVisited[i]
        if ch == "{" { depth += 1 }
        if ch == "}" {
            depth -= 1
            if depth == 0 {
                end = i
                break
            }
        }
        i = fromVisited.index(after: i)
    }
    let body = String(fromVisited[open...end])
    if body.contains("blockquote") || body.contains("pre") || body.contains("code") {
        throw TestError("\(scssPath.path): &:visited still nests blockquote/pre/code borders")
    }
    guard source.contains("blockquote, pre, code") ||
            (source.contains("blockquote") && source.contains("border: 1px solid #e8e8e8")) else {
        throw TestError("\(scssPath.path) must still define blockquote/pre/code borders")
    }
    print("ok: style.scss border rules are not nested under a:visited")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
