<!-- markdownlint-disable MD041 -->
{% assign sort_algorithm = include.algorithm %}
{% assign algo = site.data.sort_algorithms[sort_algorithm] %}
{% assign needs_insertion_sort = algo.insertion_sort | default: false %}
{% assign needs_partition_at = algo.partition_at | default: false %}
{% assign needs_partition = algo.partition | default: false %}
{% assign needs_quick_sort = algo.quick_sort | default: false %}
{% assign needs_heap_sort = algo.heap_sort | default: false %}
{% assign needs_merge_values = algo.merge_values | default: false %}
{% assign has_quadratic_average = algo.quadratic_average | default: false %}
{% assign max_power_override = algo.max_power %}

<details markdown="1">
<summary>計測に使用したコードを表示する</summary>

<div class="sort-benchmark-code" data-sort-benchmark-code markdown="1">
<button type="button" class="sort-benchmark-code__copy" data-sort-benchmark-copy aria-label="計測コードをコピー">コピー</button>

```swift
#!/usr/bin/env swift
import Foundation

// This standalone Swift driver creates the same temporary Docker build
// context as the former shell wrapper.  The benchmark program itself remains
// embedded below so readers can copy one complete, reproducible file.
struct BenchmarkError: Error, CustomStringConvertible {
    let message: String

    var description: String { message }

    init(_ message: String) {
        self.message = message
    }
}

func runCommand(_ executable: String, _ arguments: [String]) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [executable] + arguments
    process.standardInput = FileHandle.standardInput
    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError

    do {
        try process.run()
    } catch {
        throw BenchmarkError("Could not start \(executable): \(error)")
    }
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw BenchmarkError(
            "Command failed (\(process.terminationStatus)): " +
            "\(executable) \(arguments.joined(separator: " "))"
        )
    }
}

do {
    // The UUID avoids collisions when two benchmark copies are run at once.
    let workdir = FileManager.default.temporaryDirectory
        .appendingPathComponent("swift-sort-benchmark-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: workdir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: workdir) }

    // A raw Swift string is used so the nested main.swift keeps its own
    // interpolation expressions such as \(seed) until Docker compiles it.
    let dockerfile = #"""
FROM swift:6.0

WORKDIR /app

RUN cat > alloc_track.c <<'ALLOC'
{% include sort-benchmark/helpers/alloc_track.c %}
ALLOC

RUN cat > main.swift <<'SWIFT'
import Foundation
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

{% include sort-benchmark/helpers/alloc_track.swift %}
{% include sort-benchmark/helpers/buffer_swap.swift %}

{%- if max_power_override %}{% assign max_power = max_power_override %}
{%- elsif has_quadratic_average %}{% assign max_power = 15 %}
{%- else %}{% assign max_power = 18 %}
{%- endif %}
let MIN_POWER: Int = 8
let MAX_POWER: Int = {{ max_power }}
let RUNS: Int = 8192

{%- if needs_insertion_sort %}
{% include sort-benchmark/helpers/insertion_sort.swift %}
{%- endif %}

{%- if needs_partition_at %}
{% include sort-benchmark/helpers/partition_at.swift %}
{%- endif %}

{%- if needs_partition %}
{% include sort-benchmark/helpers/partition.swift %}
{%- endif %}

{%- if needs_quick_sort %}
{% include sort-benchmark/helpers/quick_sort.swift %}
{%- endif %}

{%- if needs_heap_sort %}
{% include sort-benchmark/helpers/heap_sort.swift %}
{%- endif %}

{%- if needs_merge_values %}
{% include sort-benchmark/helpers/merge_values.swift %}
{%- endif %}

{% capture sort_benchmark_algo %}sort-benchmark/algorithms/{{ sort_algorithm }}.swift{% endcapture %}
{% include {{ sort_benchmark_algo }} %}

func benchmark_sort(_ array: inout [Int]) {
{% if algo.sort_fn %}
    {{ algo.sort_fn }}(&array)
{% else %}
    fatalError("unknown algorithm: {{ sort_algorithm }}")
{% endif %}
}

{% include sort-benchmark/helpers/verify_correctness.swift %}

func shuffled(_ size: Int, seed: UInt64) -> [Int] {
    guard size > 0 else { return [] }

    var v = Array(1...size)
    var state = seed

    if size > 1 {
        for i in stride(from: size - 1, through: 1, by: -1) {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17

            let j = Int(state % UInt64(i + 1))
            v.swapAt(i, j)
        }
    }

    return v
}

func micros(_ d: Duration) -> UInt64 {
    let c = d.components
    let fromSeconds = UInt64(c.seconds) * 1_000_000
    let fromAttos = UInt64(max(0, c.attoseconds / 1_000_000_000_000))
    return fromSeconds + fromAttos
}

func padLeft(_ value: String, _ width: Int) -> String {
    if value.count >= width {
        return value
    }
    return String(repeating: " ", count: width - value.count) + value
}

func formatSeconds(_ micros: UInt64) -> String {
    let whole = micros / 1_000_000
    let frac = micros % 1_000_000
    let fracStr = padLeft(String(frac), 6).replacingOccurrences(of: " ", with: "0")
    return "\(whole).\(fracStr)"
}

func input_array(_ size: Int, seed: UInt64) -> [Int] {
    shuffled(size, seed: seed)
}

/// Peak heap growth during `benchmark_sort`, in bytes (explicit buffers such as swap).
/// Kept in bytes so the parent can average before rounding; converting to KiB here
/// would truncate sub-KiB buffers to 0 in every run and hide them from the average.
func run_once(size: Int, seed: Int) -> (UInt64, Int) {
    var array = input_array(size, seed: UInt64(seed))

    let baseBytes = alloc_track_live()
    alloc_track_reset_peak()

    let start = ContinuousClock.now

    benchmark_sort(&array)

    let elapsed = ContinuousClock.now - start
    let peakBytes = alloc_track_peak()
    let auxBytes = max(0, peakBytes - baseBytes)

    let expected: [Int] = size > 0 ? Array(1...size) : []
    if array != expected {
        fatalError("sort failed with seed \(seed) for size \(size)")
    }

    return (micros(elapsed), auxBytes)
}

func run_child(_ args: [String]) {
    let size = Int(args[2])!
    let seed = Int(args[3])!
    let (elapsedUs, mem) = run_once(size: size, seed: seed)
    print("\(elapsedUs) \(mem)")
}

let args = CommandLine.arguments
if args.count > 1 && args[1] == "--run-once" {
    run_child(args)
} else {
    run_correctness_checks()

    let tableHeader =
        "| \(padLeft("Size", 10)) | " +
        "\(padLeft("Average time (s)", 16)) | " +
        "\(padLeft("Maximum time (s)", 16)) | " +
        "\(padLeft("Average memory (KiB)", 20)) | " +
        "\(padLeft("Maximum memory (KiB)", 20)) |"
    print(tableHeader)
    print("|----------:|----------------:|----------------:|--------------------:|--------------------:|")

    for power in MIN_POWER...MAX_POWER {
        let size = 1 << power

        var totalTime: UInt64 = 0
        var maxTime: UInt64 = 0

        var totalMem = 0
        var maxMem = 0

        for seed in 1...RUNS {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: args[0])
            process.arguments = ["--run-once", "\(size)", "\(seed)"]
            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            do {
                try process.run()
            } catch {
                fatalError("failed to run benchmark child process: \(error)")
            }
            process.waitUntilExit()

            if process.terminationStatus != 0 {
                let err = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                fatalError("benchmark child process failed: \(err)")
            }

            let data = stdout.fileHandleForReading.readDataToEndOfFile()
            let stdoutText = String(data: data, encoding: .utf8) ?? ""
            let fields = stdoutText.split(whereSeparator: \.isWhitespace)
            guard fields.count >= 2,
                  let elapsedUs = UInt64(fields[0]),
                  let auxMem = Int(fields[1]) else {
                fatalError("invalid child process output: \(stdoutText)")
            }

            totalTime += elapsedUs
            if elapsedUs > maxTime {
                maxTime = elapsedUs
            }

            totalMem += auxMem
            if auxMem > maxMem {
                maxMem = auxMem
            }
        }

        let avgTime = totalTime / UInt64(RUNS)
        // Memory is summed in bytes and converted to KiB once, after averaging.
        let avgMemKb = totalMem / RUNS / 1024
        let maxMemKb = maxMem / 1024

        let tableRow =
            "| \(padLeft(String(size), 10)) | " +
            "\(padLeft(formatSeconds(avgTime), 16)) | " +
            "\(padLeft(formatSeconds(maxTime), 16)) | " +
            "\(padLeft(String(avgMemKb), 20)) | " +
            "\(padLeft(String(maxMemKb), 20)) |"
        print(tableRow)
    }
}
SWIFT

RUN clang -O2 -fPIC -shared alloc_track.c -o liballoc_track.so -ldl

RUN swiftc -Ounchecked -whole-module-optimization \
    main.swift \
    -o swift-benchmark \
    -L. -lalloc_track \
    -Xlinker -rpath -Xlinker /app

ENV LD_PRELOAD=/app/liballoc_track.so
CMD ["./swift-benchmark"]
"""#
    try dockerfile.write(
        to: workdir.appendingPathComponent("Dockerfile"),
        atomically: true,
        encoding: .utf8
    )

    // Keeping build and run as separate child processes preserves Docker's
    // normal output and the original image tag used by the benchmark skill.
    try runCommand("docker", ["build", "-t", "swift-benchmark", workdir.path])
    try runCommand("docker", ["run", "--rm", "--init", "swift-benchmark"])
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
```

</div>

</details>
