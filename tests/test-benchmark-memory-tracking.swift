#!/usr/bin/env swift
import Foundation

// Regression: the sort-benchmark harness must measure peak heap growth during
// the sort itself.  The test intentionally checks the committed include,
// because that file is the source copied into every published benchmark.

struct TestError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }

    init(_ message: String) {
        self.message = message
    }
}

let root = repositoryRoot()
let benchmarkPath = root.appendingPathComponent("_includes/sort-benchmark.md")

do {
    guard FileManager.default.fileExists(atPath: benchmarkPath.path) else {
        throw TestError("missing \(benchmarkPath.path)")
    }
    let benchmark = try String(contentsOf: benchmarkPath, encoding: .utf8)

    // These old Rust/RSS markers must stay absent.  Their presence would mean
    // that a future edit accidentally brought the previous measurement model
    // back into the now-Swift harness.
    for forbidden in ["VmHWM", "--baseline-once"] {
        if benchmark.contains(forbidden) {
            throw TestError("\(benchmarkPath.path) still references \(forbidden)")
        }
    }

    // The allocator bridge exposes live bytes and a resettable peak counter.
    // Keeping the assertions separate makes a missing part of the protocol
    // easy to diagnose from CI output.
    let required = [
        "alloc_track_live()",
        "alloc_track_reset_peak()",
        "alloc_track_peak()",
        "let auxBytes = max(0, peakBytes - baseBytes)",
        "totalMem / RUNS / 1024",
    ]
    for piece in required where !benchmark.contains(piece) {
        throw TestError("\(benchmarkPath.path) missing allocation-tracking piece: \(piece)")
    }

    // Auxiliary bytes must remain raw until all runs have been averaged.
    // Rounding each child result first would make small temporary buffers look
    // like zero memory and would change the published measurement.
    if benchmark.contains("auxBytes / 1024") || benchmark.contains("auxBytes /1024") {
        throw TestError("\(benchmarkPath.path) rounds auxiliary memory before averaging")
    }

    print("ok: sort-benchmark measures auxiliary memory via allocation peak tracking")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
