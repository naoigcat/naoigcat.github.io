#!/usr/bin/env swift
import Foundation

// Regression: the site chrome is light-only, so sort-demo.css must not add
// an isolated prefers-color-scheme: dark override that inverts only demos.

let root = repositoryRoot()
let cssPath = root.appendingPathComponent("assets/css/sort-demo.css")

do {
    let css = try String(contentsOf: cssPath, encoding: .utf8)
    let pattern = "prefers-color-scheme:\\s*dark"
    let regex = try NSRegularExpression(pattern: pattern)
    let range = NSRange(css.startIndex..<css.endIndex, in: css)
    if regex.firstMatch(in: css, range: range) != nil {
        let matchingLines = css.components(separatedBy: .newlines).enumerated().compactMap { index, line in
            line.range(of: pattern, options: .regularExpression) == nil
                ? nil
                : "\(index + 1):\(line)"
        }
        fputs(matchingLines.joined(separator: "\n") + "\n", stderr)
        fputs("sort-demo.css must not define dark-scheme overrides without a site dark theme\n", stderr)
        exit(1)
    }
    print("ok: sort-demo.css has no orphan prefers-color-scheme: dark rules")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
