#!/usr/bin/env swift
import Foundation

// Regression: non-overlapping duplicate rule blocks for the same selector
// must stay merged in sort-demo.css (cascade was never intentional).

typealias TestError = ScriptError

let root = repositoryRoot()
let cssPath = root.appendingPathComponent("assets/css/sort-demo.css")

/// Counts top-level (non-nested) rule selector lists that contain `needle`
/// as a comma-separated selector entry.  Media-query bodies are ignored so
/// responsive overrides may still mention the same selector.
func topLevelSelectorOccurrences(in css: String, needle: String) -> Int {
    var count = 0
    var depth = 0
    var pending = ""
    var i = css.startIndex
    while i < css.endIndex {
        let ch = css[i]
        if ch == "{" {
            if depth == 0 {
                let selectors = pending
                    .components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if selectors.contains(needle) {
                    count += 1
                }
            }
            depth += 1
            pending = ""
        } else if ch == "}" {
            depth = max(0, depth - 1)
            pending = ""
        } else if depth == 0 {
            pending.append(ch)
        }
        i = css.index(after: i)
    }
    return count
}

do {
    let css = try String(contentsOf: cssPath, encoding: .utf8)
    let expectedOnce = [
        "#van-emde-boas-sort-demo .veb-demo__leaf",
        ".sort-demo-unshuffle__merged-track",
        ".sort-demo-polyphase__tape-runs .sort-demo-polyphase__run--dummy",
    ]
    for selector in expectedOnce {
        let hits = topLevelSelectorOccurrences(in: css, needle: selector)
        guard hits == 1 else {
            throw TestError(
                "\(cssPath.path): top-level selector \(selector) appears \(hits) time(s); expected 1"
            )
        }
    }
    print("ok: sort-demo.css merged the duplicate top-level selector blocks")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
