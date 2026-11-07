#!/usr/bin/env swift
import Foundation

// Exercise the shared Docker driver without compiling or running article algorithms.
let root = repositoryRoot()

do {
    let source = try String(contentsOf: root.appendingPathComponent("_includes/sort-benchmark.md"), encoding: .utf8)
    guard let start = source.range(of: "```swift\n"),
          let end = source.range(of: "\n```", range: start.upperBound..<source.endIndex) else {
        throw ScriptError("Benchmark driver code fence not found")
    }
    var driver = String(source[start.upperBound..<end.lowerBound])
    guard let payloadStart = driver.range(of: "    let dockerfile = #\"\"\""),
          let payloadEnd = driver.range(of: "\"\"\"#", range: payloadStart.upperBound..<driver.endIndex),
          let commandStart = driver.range(of: "func runCommand("),
          let commandEnd = driver.range(of: "\ndo {", range: commandStart.upperBound..<driver.endIndex) else {
        throw ScriptError("Benchmark driver boundaries not found")
    }
    driver.replaceSubrange(payloadStart.lowerBound..<payloadEnd.upperBound, with: "    let dockerfile = \"\"")
    // Model a second build retagging the image before the first driver's run.
    let fakeDocker = #"""
    var builtTag = ""
    func runCommand(_ executable: String, _ arguments: [String]) throws {
        guard executable == "docker" else { throw BenchmarkError("unexpected executable") }
        if arguments.first == "build" {
            if CommandLine.arguments[1] == "build-failure" {
                throw BenchmarkError("simulated build failure")
            }
            builtTag = arguments[arguments.firstIndex(of: "-t")! + 1]
        } else if arguments.first == "run" {
            let reference = arguments.last!
            let tagImage = CommandLine.arguments[1] == "retagged" ? "sha256:other" : "sha256:built"
            let image = reference == "swift-benchmark" ? tagImage : (reference == builtTag ? "sha256:built" : reference)
            guard image == "sha256:built" else { throw BenchmarkError("ran another build's image: \(image)") }
            print("ran expected image: \(reference)")
            if CommandLine.arguments[1] == "run-failure" {
                throw BenchmarkError("simulated run failure")
            }
        } else if arguments.prefix(2) == ["image", "rm"] {
            guard arguments.last == builtTag else { throw BenchmarkError("removed another build's tag") }
            print("removed own tag")
        } else {
            throw BenchmarkError("unexpected Docker command")
        }
    }
    """#
    driver.replaceSubrange(commandStart.lowerBound..<commandEnd.lowerBound, with: fakeDocker + "\n")

    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("benchmark-identity-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let script = directory.appendingPathComponent("driver.swift")
    try driver.write(to: script, atomically: true, encoding: .utf8)

    var tags = Set<String>()
    for scenario in ["normal", "retagged", "build-failure", "run-failure"] {
        let result = try runCommand("swift", [script.path, scenario], currentDirectory: root)
        if scenario == "build-failure" {
            guard result.status != 0, result.stdout.isEmpty,
                  result.stderr.contains("simulated build failure") else {
                throw ScriptError("Failed builds must not run an image: \(result.stderr)")
            }
        } else {
            let lines = result.stdout.split(separator: "\n").map(String.init)
            guard result.status == (scenario == "run-failure" ? 1 : 0),
                  lines.count == 2, lines[0].hasPrefix("ran expected image: swift-benchmark:"),
                  lines[1] == "removed own tag" else {
                throw ScriptError("\(scenario): \(result.stderr)")
            }
            guard tags.insert(lines[0]).inserted else { throw ScriptError("Image tag reused between runs") }
            if scenario == "run-failure", !result.stderr.contains("simulated run failure") {
                throw ScriptError("Run failure was swallowed")
            }
        }
    }
    print("ok: benchmark runs its built image despite tag changes and stops on build failure")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
