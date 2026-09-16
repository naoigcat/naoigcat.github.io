#!/usr/bin/env swift
import Foundation

// Regression: only the intentionally publishable top-level paths may remain
// outside Jekyll's exclude list.  This is a small YAML reader on purpose: the
// checked section is a flat list, so invoking a full YAML runtime would add a
// dependency to a source-layout test for no benefit.

struct TestError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }

    init(_ message: String) {
        self.message = message
    }
}

func topLevelExcludeEntries(from text: String) -> [String] {
    let lines = text.components(separatedBy: .newlines)
    guard let marker = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "exclude:" }) else {
        return []
    }

    var result: [String] = []
    for line in lines.dropFirst(marker + 1) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("-") {
            let value = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
            if !value.isEmpty {
                result.append(String(value))
            }
            continue
        }

        // A non-indented line starts the next YAML key.  Blank and comment
        // lines are harmless and can be skipped while still inside the list.
        if !line.isEmpty && line.first?.isWhitespace == false {
            break
        }
    }
    return result
}

let root = repositoryRoot()
let configPath = root.appendingPathComponent("_config.yml")

do {
    let config = try String(contentsOf: configPath, encoding: .utf8)
    let excluded = topLevelExcludeEntries(from: config)
    guard !excluded.isEmpty else {
        throw TestError("exclude: list is missing or empty in \(configPath.path)")
    }

    // These are the only top-level entries the site is expected to publish.
    // Hidden files and Jekyll's underscore-prefixed directories are filtered
    // before this comparison, matching the old shell test's candidate set.
    let whitelist = [
        "404.html",
        "apple-touch-icon-precomposed.png",
        "apple-touch-icon.png",
        "assets",
        "favicon.ico",
        "index.md",
        "tags",
    ]
    let entries = try FileManager.default.contentsOfDirectory(
        at: root,
        includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
        options: [.skipsHiddenFiles]
    )
    let candidates = entries
        .map(\.lastPathComponent)
        .filter { name in
            guard let first = name.first else { return false }
            return first != "_" && first != "#" && first != "~"
        }
        .sorted()
    let included = candidates.filter { !excluded.contains($0) }

    guard included == whitelist else {
        fputs("publishable top-level paths must equal the whitelist\n", stderr)
        fputs("whitelist:\n\(whitelist.joined(separator: "\n"))\n", stderr)
        fputs("actual (candidates minus exclude):\n\(included.joined(separator: "\n"))\n", stderr)
        fputs("exclude:\n\(excluded.joined(separator: "\n"))\n", stderr)
        exit(1)
    }

    print("ok: only whitelisted top-level paths remain outside exclude")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
