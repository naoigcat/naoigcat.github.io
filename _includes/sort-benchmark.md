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

<details markdown="1">
<summary>計測に使用したコードを表示する</summary>

<div class="sort-benchmark-code" data-sort-benchmark-code markdown="1">
<button type="button" class="sort-benchmark-code__copy" data-sort-benchmark-copy aria-label="計測コードをコピー">コピー</button>

```bash
set -euo pipefail

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

cat > "$WORKDIR/Dockerfile" <<'EOF'
FROM rust:1.95.0

WORKDIR /app

RUN mkdir -p src

RUN cat > Cargo.toml <<'CARGO'
[package]
name = "rust-benchmark"
version = "0.1.0"
edition = "2021"

[profile.release]
lto = true
codegen-units = 1
panic = "abort"
CARGO

RUN cat > src/main.rs <<'RUST'
use std::{
    env,
    process::Command,
    time::{Duration, Instant},
};

{%- if has_quadratic_average %}
const MIN_POWER: u32 = 8;
const MAX_POWER: u32 = 15;
{%- else %}
const MIN_POWER: u32 = 8;
const MAX_POWER: u32 = 18;
{%- endif %}
const RUNS: usize = 8192;

{%- if needs_insertion_sort %}
{% include sort-benchmark/helpers/insertion_sort.rs %}
{%- endif %}

{%- if needs_partition_at %}
{% include sort-benchmark/helpers/partition_at.rs %}
{%- endif %}

{%- if needs_partition %}
{% include sort-benchmark/helpers/partition.rs %}
{%- endif %}

{%- if needs_quick_sort %}
{% include sort-benchmark/helpers/quick_sort.rs %}
{%- endif %}

{%- if needs_heap_sort %}
{% include sort-benchmark/helpers/heap_sort.rs %}
{%- endif %}

{%- if needs_merge_values %}
{% include sort-benchmark/helpers/merge_values.rs %}
{%- endif %}

{% capture sort_benchmark_algo %}sort-benchmark/algorithms/{{ sort_algorithm }}.rs{% endcapture %}
{% include {{ sort_benchmark_algo }} %}

fn benchmark_sort(array: &mut [usize]) {
{% if algo.sort_fn %}
    {{ algo.sort_fn }}(array);
{% else %}
    panic!("unknown algorithm: {{ sort_algorithm }}");
{% endif %}
}

fn shuffled(size: usize, seed: u64) -> Vec<usize> {
    let mut v: Vec<usize> = (1..=size).collect();

    let mut state = seed;

    for i in (1..size).rev() {
        state ^= state << 13;
        state ^= state >> 7;
        state ^= state << 17;

        let j = (state as usize) % (i + 1);

        v.swap(i, j);
    }

    v
}

fn memory_usage_kb() -> usize {
    // VmHWM (peak RSS, KiB). Reported memory subtracts a per-size baseline that only
    // holds the input array, so the table reflects auxiliary space during sorting.
    let contents = std::fs::read_to_string("/proc/self/status")
        .unwrap_or_default();

    for line in contents.lines() {
        if let Some(rest) = line.strip_prefix("VmHWM:") {
            let kb = rest
                .split_whitespace()
                .next()
                .unwrap_or("0")
                .parse::<usize>()
                .unwrap_or(0);

            return kb;
        }
    }

    0
}

fn micros(d: Duration) -> u128 {
    d.as_micros()
}

fn input_array(size: usize, seed: u64) -> Vec<usize> {
    shuffled(size, seed)
}

fn run_baseline(size: usize) -> usize {
    let _hold = input_array(size, 1);
    memory_usage_kb()
}

fn run_once(size: usize, seed: usize) -> (u128, usize) {
    let mut array = input_array(size, seed as u64);

    let start = Instant::now();

    benchmark_sort(&mut array);

    let elapsed = start.elapsed();
    let mem = memory_usage_kb();

    let expected: Vec<usize> = (1..=size).collect();
    if array != expected {
        panic!(
            "sort failed with seed {} for size {}",
            seed,
            size
        );
    }

    (micros(elapsed), mem)
}

fn run_baseline_child(args: &[String]) {
    let size = args[2].parse::<usize>().expect("invalid size");
    let mem = run_baseline(size);
    println!("{}", mem);
}

fn run_child(args: &[String]) {
    let size = args[2].parse::<usize>().expect("invalid size");
    let seed = args[3].parse::<usize>().expect("invalid seed");
    let (elapsed_us, mem) = run_once(size, seed);
    println!("{} {}", elapsed_us, mem);
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.get(1).is_some_and(|arg| arg == "--baseline-once") {
        run_baseline_child(&args);
        return;
    }
    if args.get(1).is_some_and(|arg| arg == "--run-once") {
        run_child(&args);
        return;
    }

    println!(
        "| {:>10} | {:>15} | {:>15} | {:>15} | {:>15} |",
        "Size",
        "Average time",
        "Maximum time",
        "Average memory",
        "Maximum memory"
    );

    println!(
        "|{:-<11}:|{:-<16}:|{:-<16}:|{:-<16}:|{:-<16}:|",
        "",
        "",
        "",
        "",
        ""
    );

    for power in MIN_POWER..=MAX_POWER {
        let size = 1usize << power;

        let baseline_output = Command::new(env::current_exe().expect("failed to find current executable"))
            .arg("--baseline-once")
            .arg(size.to_string())
            .output()
            .expect("failed to run benchmark baseline process");

        if !baseline_output.status.success() {
            panic!(
                "benchmark baseline process failed: {}",
                String::from_utf8_lossy(&baseline_output.stderr)
            );
        }

        let baseline_stdout = String::from_utf8(baseline_output.stdout)
            .expect("baseline process returned non-UTF-8 output");
        let baseline_mem = baseline_stdout
            .split_whitespace()
            .next()
            .expect("missing baseline memory usage")
            .parse::<usize>()
            .expect("invalid baseline memory usage");

        let mut total_time: u128 = 0;
        let mut max_time: u128 = 0;

        let mut total_mem: usize = 0;
        let mut max_mem: usize = 0;

        for seed in 1..=RUNS {
            let output = Command::new(env::current_exe().expect("failed to find current executable"))
                .arg("--run-once")
                .arg(size.to_string())
                .arg(seed.to_string())
                .output()
                .expect("failed to run benchmark child process");

            if !output.status.success() {
                panic!(
                    "benchmark child process failed: {}",
                    String::from_utf8_lossy(&output.stderr)
                );
            }

            let stdout = String::from_utf8(output.stdout)
                .expect("child process returned non-UTF-8 output");
            let mut fields = stdout.split_whitespace();
            let elapsed_us = fields
                .next()
                .expect("missing elapsed time")
                .parse::<u128>()
                .expect("invalid elapsed time");
            let mem = fields
                .next()
                .expect("missing memory usage")
                .parse::<usize>()
                .expect("invalid memory usage");

            total_time += elapsed_us;

            if elapsed_us > max_time {
                max_time = elapsed_us;
            }

            let aux_mem = mem.saturating_sub(baseline_mem);

            total_mem += aux_mem;

            if aux_mem > max_mem {
                max_mem = aux_mem;
            }
        }

        let avg_time = total_time / RUNS as u128;
        let avg_mem = total_mem / RUNS;

        println!(
            "| {:>10} | {:>15} | {:>15} | {:>15} | {:>15} |",
            size,
            format!("{}.{:06}", avg_time / 1_000_000, avg_time % 1_000_000),
            format!("{}.{:06}", max_time / 1_000_000, max_time % 1_000_000),
            avg_mem,
            max_mem
        );
    }
}
RUST

RUN cargo build --release

CMD ["./target/release/rust-benchmark"]
EOF

docker build -t rust-benchmark "$WORKDIR"
docker run --rm --init rust-benchmark
```

</div>

</details>
