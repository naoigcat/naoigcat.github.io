#!/usr/bin/env swift
import Foundation

// Regression: committed assets/tags JSON must agree with post front matter,
// and every tags_embed entry must point at a real on-demand JSON file.
//
// The check is intentionally implemented with Foundation only.  The format
// being checked is a small, stable subset of front matter and JSON, so pulling
// a YAML package into the repository's infrastructure tests would add more
// moving parts than it removes.

struct PostInfo {
    let title: String
    let url: String
    let date: String
    let order: Int
}

struct ComparablePost: Equatable {
    let title: String?
    let url: String?
}

struct TestError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }

    init(_ message: String) {
        self.message = message
    }
}

func files(under directory: URL, fileExtension: String) -> [URL] {
    (FileManager.default.enumerator(
        at: directory,
        includingPropertiesForKeys: [.isRegularFileKey]
    )?.allObjects ?? [])
        .compactMap { $0 as? URL }
        .filter { $0.pathExtension == fileExtension }
        .sorted { $0.path < $1.path }
}

func firstCapture(
    _ pattern: String,
    in text: String,
    options: NSRegularExpression.Options = [.anchorsMatchLines]
) -> String? {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
        return nil
    }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges > 1 else {
        return nil
    }
    guard let capture = Range(match.range(at: 1), in: text) else { return nil }
    return String(text[capture])
}

func relativePath(_ path: URL, from root: URL) -> String {
    path.path.replacingOccurrences(of: root.path + "/", with: "")
}

let scriptURL = URL(fileURLWithPath: #filePath).standardizedFileURL
let root = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let postsDirectory = root.appendingPathComponent("_posts")
let tagsDirectory = root.appendingPathComponent("assets/tags")
let embedPath = root.appendingPathComponent("_data/tags_embed.yml")

do {
    var errors: [String] = []
    var tagToPosts: [String: [PostInfo]] = [:]

    // Build the expected tag index from the source posts first.  Keeping the
    // original order number gives us the same stable ordering as Python's
    // sorted(..., reverse=True) for posts sharing a date.
    for path in files(under: postsDirectory, fileExtension: "md") {
        let relative = relativePath(path, from: root)
        let text = try String(contentsOf: path, encoding: .utf8)
        let lines = text.components(separatedBy: .newlines)
        guard lines.first == "---" else {
            errors.append("\(relative): missing front matter")
            continue
        }
        guard let end = lines.dropFirst().firstIndex(of: "---") else {
            errors.append("\(relative): unclosed front matter")
            continue
        }
        let frontMatter = lines[1..<end].joined(separator: "\n")

        guard let title = firstCapture(#"^title:\s*(.*)$"#, in: frontMatter) else {
            errors.append("\(relative): missing title")
            continue
        }
        guard let tagsText = firstCapture(#"^tags:\s*(.*)$"#, in: frontMatter),
              !tagsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errors.append("\(relative): missing inline tags")
            continue
        }
        guard let date = firstCapture(#"^date:\s*(\d{4}-\d{2}-\d{2})"#, in: frontMatter) else {
            errors.append("\(relative): missing date")
            continue
        }

        let filename = path.lastPathComponent
        let filenamePattern = #"^(\d{4})-(\d{2})-(\d{2})-(.+)\.md$"#
        let filenameRegex = try NSRegularExpression(pattern: filenamePattern)
        let filenameRange = NSRange(filename.startIndex..<filename.endIndex, in: filename)
        guard let match = filenameRegex.firstMatch(in: filename, range: filenameRange),
              let yearRange = Range(match.range(at: 1), in: filename),
              let monthRange = Range(match.range(at: 2), in: filename),
              let dayRange = Range(match.range(at: 3), in: filename),
              let slugRange = Range(match.range(at: 4), in: filename) else {
            errors.append("\(relative): unexpected filename")
            continue
        }
        let year = String(filename[yearRange])
        let month = String(filename[monthRange])
        let day = String(filename[dayRange])
        let slug = String(filename[slugRange])
        let url = "/\(year)/\(month)/\(day)/\(slug).html"
        let tags = tagsText.split(whereSeparator: \.isWhitespace).map(String.init)
        for tag in tags {
            let order = tagToPosts[tag]?.count ?? 0
            tagToPosts[tag, default: []].append(PostInfo(title: title, url: url, date: date, order: order))
        }
    }

    var jsonNames = Set<String>()
    guard FileManager.default.fileExists(atPath: tagsDirectory.path) else {
        throw TestError("missing \(tagsDirectory.path)")
    }

    for path in files(under: tagsDirectory, fileExtension: "json") {
        let relative = relativePath(path, from: root)
        let data = try Data(contentsOf: path)
        let decoded: Any
        do {
            decoded = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        } catch {
            errors.append("\(relative): invalid JSON (\(error))")
            continue
        }
        guard let object = decoded as? [String: Any] else {
            errors.append("\(relative): JSON root must be an object")
            continue
        }

        for key in ["name", "slug", "posts"] where object[key] == nil {
            errors.append("\(relative): missing '\(key)'")
        }

        guard let name = object["name"] as? String, !name.isEmpty else {
            errors.append("\(relative): name must be a non-empty string")
            continue
        }
        let stem = path.deletingPathExtension().lastPathComponent
        if (object["slug"] as? String) != stem {
            errors.append("\(relative): slug '\(object["slug"] ?? "nil")' must equal filename stem '\(stem)'")
        }
        if name != stem {
            errors.append("\(relative): name '\(name)' must equal filename stem '\(stem)'")
        }
        jsonNames.insert(name)

        guard let rawPosts = object["posts"] as? [Any] else {
            errors.append("\(relative): posts must be a list")
            continue
        }

        var got: [ComparablePost] = []
        for (index, rawPost) in rawPosts.enumerated() {
            guard let post = rawPost as? [String: Any] else {
                errors.append("\(relative): posts[\(index)] must be an object")
                continue
            }
            for key in ["title", "url", "date"] where post[key] == nil {
                errors.append("\(relative): posts[\(index)] missing '\(key)'")
            }
            got.append(ComparablePost(title: post["title"] as? String, url: post["url"] as? String))
        }

        let expected = (tagToPosts[name] ?? [])
            .sorted {
                if $0.date != $1.date { return $0.date > $1.date }
                return $0.order < $1.order
            }
            .map { ComparablePost(title: $0.title, url: $0.url) }
        if got != expected {
            errors.append(
                "\(relative): post list does not match front matter " +
                "(json=\(got.count), posts=\(expected.count))"
            )
            for index in 0..<min(got.count, expected.count) where got[index] != expected[index] {
                errors.append("  first diff at index \(index): json=\(String(describing: got[index])), posts=\(String(describing: expected[index]))")
                break
            }
            if got.count != expected.count {
                let jsonURLs = Set(got.compactMap(\.url))
                let postURLs = Set(expected.compactMap(\.url))
                let onlyJSON = jsonURLs.subtracting(postURLs).sorted()
                let onlyPosts = postURLs.subtracting(jsonURLs).sorted()
                if !onlyJSON.isEmpty { errors.append("  only in JSON: \(Array(onlyJSON.prefix(5)))") }
                if !onlyPosts.isEmpty { errors.append("  only in posts: \(Array(onlyPosts.prefix(5)))") }
            }
        }
    }

    let sourceNames = Set(tagToPosts.keys)
    let missingJSON = sourceNames.subtracting(jsonNames).sorted()
    let extraJSON = jsonNames.subtracting(sourceNames).sorted()
    if !missingJSON.isEmpty { errors.append("tag JSON missing for: \(missingJSON)") }
    if !extraJSON.isEmpty { errors.append("tag JSON without posts: \(extraJSON)") }

    if !FileManager.default.fileExists(atPath: embedPath.path) {
        errors.append("missing \(relativePath(embedPath, from: root))")
    } else {
        let embedLines = try String(contentsOf: embedPath, encoding: .utf8).components(separatedBy: .newlines)
        let embedSlugs = embedLines.compactMap { line -> String? in
            let stripped = line.trimmingCharacters(in: .whitespaces)
            guard stripped.hasPrefix("- ") else { return nil }
            return String(stripped.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        }
        if embedSlugs.isEmpty {
            errors.append("tags_embed.yml has no slugs")
        }
        for slug in embedSlugs where !FileManager.default.fileExists(atPath: tagsDirectory.appendingPathComponent("\(slug).json").path) {
            errors.append("tags_embed slug '\(slug)' has no assets/tags/\(slug).json")
        }
    }

    guard errors.isEmpty else {
        fputs("tag JSON sync failed:\n", stderr)
        for error in errors {
            fputs("\(error)\n", stderr)
        }
        exit(1)
    }

    let linkCount = tagToPosts.values.reduce(0) { $0 + $1.count }
    print("ok: \(jsonNames.count) tag JSON file(s) match \(linkCount) post-tag link(s)")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
