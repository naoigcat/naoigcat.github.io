#!/usr/bin/env swift
import Foundation

// Regression: every inline DemoSort.attachPlayback options object must set
// barClass.  DemoSort.mountBars uses that class to make the generated bars
// visible; omitting it produces a demo that is technically present but
// visually empty.

struct TestError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }

    init(_ message: String) {
        self.message = message
    }
}

struct OptionsScan {
    let block: String?
    let resume: String.Index
    let error: String?
}

let marker = "DemoSort.attachPlayback("

/// Finds the object literal immediately following an attachPlayback call.
///
/// A simple regular expression cannot balance nested braces.  This scanner
/// therefore understands strings and both JavaScript comment forms before it
/// counts braces.  That keeps captions containing a literal closing brace from
/// causing a false match.
func findOptionsBlock(in text: String, after callEnd: String.Index) -> OptionsScan {
    let end = text.endIndex
    var cursor = callEnd

    // Whitespace is allowed between the opening parenthesis and the object,
    // but a variable such as attachPlayback(options) is intentionally rejected.
    while cursor < end && text[cursor].isWhitespace {
        cursor = text.index(after: cursor)
    }
    guard cursor < end, text[cursor] == "{" else {
        return OptionsScan(
            block: nil,
            resume: callEnd,
            error: "options must be an inline object literal starting with '{'"
        )
    }

    let braceStart = cursor
    var depth = 0
    let quoteCharacters: Set<Character> = ["'", "\"", "\u{60}"]

    while cursor < end {
        let character = text[cursor]

        if quoteCharacters.contains(character) {
            // Skip a complete quoted token.  Backslash escapes consume the
            // following character so an escaped quote cannot end the token.
            let quote = character
            cursor = text.index(after: cursor)
            while cursor < end {
                let inner = text[cursor]
                if inner == "\\" {
                    cursor = text.index(after: cursor)
                    if cursor < end {
                        cursor = text.index(after: cursor)
                    }
                    continue
                }
                if inner == quote {
                    cursor = text.index(after: cursor)
                    break
                }
                // JavaScript single- and double-quoted strings cannot contain
                // a raw newline.  Stop here so the outer scanner can report an
                // unclosed object instead of looping indefinitely.
                if quote != "\u{60}" && inner == "\n" {
                    break
                }
                cursor = text.index(after: cursor)
            }
            continue
        }

        if text[cursor...].hasPrefix("//") {
            // A line comment has no braces that belong to the object.
            cursor = text.index(cursor, offsetBy: 2)
            if let newline = text[cursor...].firstIndex(of: "\n") {
                cursor = newline
            } else {
                break
            }
            continue
        }

        if text[cursor...].hasPrefix("/*") {
            // Likewise skip block comments, including any brace-looking text.
            guard let closing = text.range(of: "*/", range: cursor..<end) else {
                break
            }
            cursor = closing.upperBound
            continue
        }

        if character == "{" {
            depth += 1
        } else if character == "}" {
            depth -= 1
            if depth == 0 {
                return OptionsScan(
                    block: String(text[braceStart...cursor]),
                    resume: text.index(after: cursor),
                    error: nil
                )
            }
        }
        cursor = text.index(after: cursor)
    }

    return OptionsScan(block: nil, resume: end, error: "unclosed options object")
}

func containsBarClass(_ block: String) -> Bool {
    guard let regex = try? NSRegularExpression(pattern: "\\bbarClass\\s*:") else {
        return false
    }
    let range = NSRange(block.startIndex..<block.endIndex, in: block)
    return regex.firstMatch(in: block, range: range) != nil
}

func checkText(_ text: String, relativePath: String, errors: inout [String]) -> Int {
    var searchFrom = text.startIndex
    var callNumber = 0
    var count = 0

    while let match = text.range(of: marker, range: searchFrom..<text.endIndex) {
        callNumber += 1
        let scan = findOptionsBlock(in: text, after: match.upperBound)
        guard let block = scan.block else {
            errors.append("\(relativePath): attachPlayback #\(callNumber): \(scan.error ?? "unknown parser error")")
            break
        }

        count += 1
        if !containsBarClass(block) {
            errors.append(
                "\(relativePath): attachPlayback #\(callNumber): missing barClass " +
                "(required so DemoSort.mountBars styles bars)"
            )
        }
        searchFrom = scan.resume
    }
    return count
}

func markdownFiles(under directory: URL) -> [URL] {
    (FileManager.default.enumerator(
        at: directory,
        includingPropertiesForKeys: [.isRegularFileKey]
    )?.allObjects ?? [])
        .compactMap { $0 as? URL }
        .filter { $0.pathExtension == "md" }
        .sorted { $0.path < $1.path }
}

let scriptURL = URL(fileURLWithPath: #filePath).standardizedFileURL
let root = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let postsDirectory = root.appendingPathComponent("_posts")

do {
    // These cases protect the scanner itself from regressing while the post
    // corpus changes.  In particular, they cover parser mistakes that can
    // hide a missing barClass behind a later object literal.
    let selfChecks: [(String, String?)] = [
        (
            "DemoSort.attachPlayback(opts);\nconst other = { barClass: 'x' };\n",
            "options must be an inline object literal"
        ),
        (
            "DemoSort.attachPlayback({\n  initialCaption: '}',\n  barClass: 'bar',\n});\n",
            nil
        ),
        (
            "DemoSort.attachPlayback({ // {\n  caption: \u{60}${x}}\u{60}, /* } */ barClass: 'bar' });\n",
            nil
        ),
        (
            "DemoSort.attachPlayback({\n  initialCaption: '}',\n});\n",
            "missing barClass"
        ),
    ]

    for (sample, expected) in selfChecks {
        var selfErrors: [String] = []
        _ = checkText(sample, relativePath: "<self-check>", errors: &selfErrors)
        let actual = selfErrors.first
        let expectationMatches = expected == nil ? actual == nil : (actual?.contains(expected!) == true)
        if !expectationMatches {
            throw TestError("self-check failed: expected \(expected ?? "no error"), got \(actual ?? "no error")")
        }
    }

    var errors: [String] = []
    var checked = 0
    for path in markdownFiles(under: postsDirectory) {
        let text = try String(contentsOf: path, encoding: .utf8)
        guard text.contains(marker) else { continue }
        let relative = path.path.replacingOccurrences(of: root.path + "/", with: "")
        checked += checkText(text, relativePath: relative, errors: &errors)
    }

    guard checked > 0 else {
        throw TestError("No DemoSort.attachPlayback calls found under _posts/")
    }
    guard errors.isEmpty else {
        fputs("Missing barClass in sort demo attachPlayback options:\n", stderr)
        for error in errors {
            fputs("  \(error)\n", stderr)
        }
        exit(1)
    }
    print("ok: \(checked) attachPlayback call(s) set barClass")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
