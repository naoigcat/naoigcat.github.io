---
title:     バブルソートで配列を並び替える
date:      2026-05-01 00:56:20 +0900
tags:      sort
sort_demo: true
---

## バブルソートを使用する

バブルソート (`bubble sort`) は、隣り合う要素を比較し、順序が逆なら入れ替える操作を繰り返すことで、配列全体を昇順（または降順）に整列させる単純な比較ソートである。小さい（または大きい）値が「泡のように」一端へ浮き上がっていく様子からこの名前が付いている。

1.  **走査開始**: 配列の先頭から、隣り合う2要素 `(a[i], a[i+1])` を順に見ていく。
2.  **交換**: `a[i] > a[i+1]` のときだけ2つを入れ替える。そうでなければ何もしない。
3.  **走査終了**: 1回の始端から終端への走査が終わると、常に大きい方が終端へ押し出されるため最大の要素は必ず終端に移動する。
4.  **繰り返し**: 配列がソートされるまで上記の走査を繰り返す。最適化として、**すでに終端に固定された最大要素**は次の走査から比較対象から外してよい。

```pseudocode
procedure bubble_sort(A)
  n = length(A)
  for i from 0 to n - 1
    swapped = false
    for j from 0 to n - 2 - i
      if A[j] > A[j + 1] then
        swap(A[j], A[j + 1])
        swapped = true
    if not swapped then
      break
```

最悪時間計算量は O(n²) で、すでにソートされている場合は O(n) となる。空間計算量は O(1) で、安定なソートである（等しいキーの相対順序を保つ）。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('bubble-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;
    let swapped;
    for (let i = 0; i < n - 1; i++) {
      swapped = false;
      for (let j = 0; j < n - 1 - i; j++) {
        steps.push({ kind: 'compare', lo: j, hi: j + 1, arr: a.slice() });
        if (a[j] > a[j + 1]) {
          const t = a[j];
          a[j] = a[j + 1];
          a[j + 1] = t;
          swapped = true;
          steps.push({ kind: 'swap', lo: j, hi: j + 1, arr: a.slice() });
        }
      }
      if (!swapped) break;
    }
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-bubble',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'バブルソートのデモ（比較はオレンジ、交換は緑の枠）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'compare']]);
        api.setCaption('比較: 位置 ' + s.lo + ' と ' + s.hi);
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.lo + 1, 'swap']]);
        api.setCaption('交換しています…');
        await DemoSort.flipAdjacentSwap(barsEl, s.lo);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '交換しました（位置 ' + s.lo + ' と ' + (s.lo + 1) + '）'
        );
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 280,
  });
});
</script>
{% endcapture %}

{% include sort-demo/wrapper.html
  id="bubble-sort-demo"
  data_prefix="bubble"
  script=sort_demo_js
%}

説明は簡単で教育的な例としてよく用いられるが、実際の用途ではクイックソートやマージソートなどのより効率的なアルゴリズムが一般的に使用される。

## 計算時間量および空間計算量を計測する

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000047 |        0.000074 |               1 |               1 |
|        512 |        0.000154 |        0.000188 |               1 |               1 |
|       1024 |        0.000526 |        0.000629 |               1 |               1 |
|       2048 |        0.001972 |        0.002238 |               1 |               1 |
|       4096 |        0.008232 |        0.018090 |               1 |               1 |
|       8192 |        0.033589 |        0.049543 |               1 |               1 |
|      16384 |        0.187774 |        0.768557 |               1 |               1 |
|      32768 |        0.963063 |        1.865158 |               2 |               2 |
|      65536 |        4.570710 |        8.073677 |               2 |               2 |

<details markdown="1">
<summary>計測に使用したコードを表示する</summary>

```bash
set -euo pipefail

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

cat > "$WORKDIR/Dockerfile" <<'EOF'
FROM rust:1.78

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
use std::time::{Duration, Instant};

const MIN_POWER: u32 = 8;
const MAX_POWER: u32 = 16;
const RUNS: usize = 1024;

fn bubble_sort(array: &mut [usize]) {
    if array.len() <= 1 {
        return;
    }

    let mut last = array.len() - 1;

    while last > 0 {
        let mut new_last = 0;

        for i in 0..last {
            if array[i] > array[i + 1] {
                array.swap(i, i + 1);
                new_last = i;
            }
        }

        last = new_last;
    }
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

fn memory_usage_mb() -> usize {
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

            return kb / 1024;
        }
    }

    0
}

fn micros(d: Duration) -> u128 {
    d.as_micros()
}

fn main() {
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

        let expected: Vec<usize> = (1..=size).collect();

        let mut total_time: u128 = 0;
        let mut max_time: u128 = 0;

        let mut total_mem: usize = 0;
        let mut max_mem: usize = 0;

        for seed in 1..=RUNS {
            let mut array = shuffled(size, seed as u64);

            let start = Instant::now();

            bubble_sort(&mut array);

            let elapsed = start.elapsed();

            if array != expected {
                panic!(
                    "sort failed with seed {} for size {}",
                    seed,
                    size
                );
            }

            let elapsed_us = micros(elapsed);

            total_time += elapsed_us;

            if elapsed_us > max_time {
                max_time = elapsed_us;
            }

            let mem = memory_usage_mb();

            total_mem += mem;

            if mem > max_mem {
                max_mem = mem;
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
docker run --rm rust-benchmark
```

</details>
