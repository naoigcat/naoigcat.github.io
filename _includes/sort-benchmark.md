<!-- markdownlint-disable MD041 -->
{% assign sort_algorithm = include.algorithm %}
{% assign sort_algorithm_key = sort_algorithm | prepend: "|" | append: "|" %}
{% assign insertion_sort_algorithms = "|insertion|quick|intro|proportion_extend|sample|symmetry_partition|tim|power|shear|" %}
{% assign partition_at_algorithms = "|quick|intro|proportion_extend|sample|symmetry_partition|" %}
{% assign partition_algorithms = "|quick|intro|sample|" %}
{% assign quick_sort_algorithms = "|quick|sample|" %}
{% assign heap_sort_algorithms = "|heap|intro|" %}
{% assign merge_values_algorithms = "|strand|cartesian_tree|" %}
{% assign quadratic_average_algorithms = "|bubble|insertion|binary_insertion|shaker|gnome|selection|oddeven|cycle|pancake|ford_johnson|" %}
{% assign needs_insertion_sort = false %}
{% assign needs_partition_at = false %}
{% assign needs_partition = false %}
{% assign needs_quick_sort = false %}
{% assign needs_heap_sort = false %}
{% assign needs_merge_values = false %}
{% assign has_quadratic_average = false %}
{% if insertion_sort_algorithms contains sort_algorithm_key %}
{% assign needs_insertion_sort = true %}
{% endif %}
{% if partition_at_algorithms contains sort_algorithm_key %}
{% assign needs_partition_at = true %}
{% endif %}
{% if partition_algorithms contains sort_algorithm_key %}
{% assign needs_partition = true %}
{% endif %}
{% if quick_sort_algorithms contains sort_algorithm_key %}
{% assign needs_quick_sort = true %}
{% endif %}
{% if heap_sort_algorithms contains sort_algorithm_key %}
{% assign needs_heap_sort = true %}
{% endif %}
{% if merge_values_algorithms contains sort_algorithm_key %}
{% assign needs_merge_values = true %}
{% endif %}
{% if quadratic_average_algorithms contains sort_algorithm_key %}
{% assign has_quadratic_average = true %}
{% endif %}

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

{%- if sort_algorithm == "bubble" %}
fn bubble_sort(a: &mut [usize]) {
    if a.len() <= 1 {
        return;
    }

    let mut last = a.len() - 1;

    while last > 0 {
        let mut new_last = 0;

        for i in 0..last {
            if a[i] > a[i + 1] {
                a.swap(i, i + 1);
                new_last = i;
            }
        }

        last = new_last;
    }
}
{%- endif %}

{%- if needs_insertion_sort %}
fn insertion_sort(a: &mut [usize]) {
    for i in 1..a.len() {
        let mut j = i;
        while j > 0 && a[j - 1] > a[j] {
            a.swap(j - 1, j);
            j -= 1;
        }
    }
}
{%- endif %}

{%- if sort_algorithm == "binary_insertion" %}
fn binary_insertion_sort(a: &mut [usize]) {
    for i in 1..a.len() {
        let key = a[i];
        let mut lo = 0;
        let mut hi = i;
        while lo < hi {
            let mid = lo + (hi - lo) / 2;
            if a[mid] > key {
                hi = mid;
            } else {
                lo = mid + 1;
            }
        }
        for j in (lo..i).rev() {
            a[j + 1] = a[j];
        }
        a[lo] = key;
    }
}
{%- endif %}

{%- if needs_partition_at %}
fn partition_at(a: &mut [usize], lo: usize, hi: usize, pivot_idx: usize) -> usize {
    a.swap(pivot_idx, hi);
    let pivot = a[hi];
    let mut i = lo;
    for j in lo..hi {
        if a[j] < pivot {
            a.swap(i, j);
            i += 1;
        }
    }
    a.swap(i, hi);
    i
}
{%- endif %}

{%- if needs_partition %}
fn partition(a: &mut [usize], lo: usize, hi: usize) -> usize {
    partition_at(a, lo, hi, lo + (hi - lo) / 2)
}
{%- endif %}

{%- if needs_quick_sort %}
fn quick_sort_range(a: &mut [usize], lo: usize, hi: usize) {
    if hi <= lo {
        return;
    }
    if hi - lo < 16 {
        insertion_sort(&mut a[lo..=hi]);
        return;
    }
    let p = partition(a, lo, hi);
    if p > 0 {
        quick_sort_range(a, lo, p - 1);
    }
    quick_sort_range(a, p + 1, hi);
}

fn quick_sort(a: &mut [usize]) {
    if let Some(hi) = a.len().checked_sub(1) {
        quick_sort_range(a, 0, hi);
    }
}
{%- endif %}

{%- if sort_algorithm == "merge" %}
fn merge_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    let mid = n / 2;
    merge_sort(&mut a[..mid]);
    merge_sort(&mut a[mid..]);
    let mut merged = Vec::with_capacity(n);
    let (mut l, mut r) = (0, mid);
    while l < mid && r < n {
        if a[l] <= a[r] {
            merged.push(a[l]);
            l += 1;
        } else {
            merged.push(a[r]);
            r += 1;
        }
    }
    merged.extend_from_slice(&a[l..mid]);
    merged.extend_from_slice(&a[r..]);
    a.copy_from_slice(&merged);
}
{%- endif %}

{%- if needs_heap_sort %}
fn sift_down(a: &mut [usize], mut root: usize, end: usize) {
    loop {
        let child = root * 2 + 1;
        if child > end {
            break;
        }
        let mut swap_idx = child;
        if child < end && a[child] < a[child + 1] {
            swap_idx = child + 1;
        }
        if a[root] >= a[swap_idx] {
            break;
        }
        a.swap(root, swap_idx);
        root = swap_idx;
    }
}

fn heap_sort(a: &mut [usize]) {
    if a.len() <= 1 {
        return;
    }
    for start in (0..a.len() / 2).rev() {
        sift_down(a, start, a.len() - 1);
    }
    for end in (1..a.len()).rev() {
        a.swap(0, end);
        sift_down(a, 0, end - 1);
    }
}
{%- endif %}

{%- if sort_algorithm == "intro" %}
fn intro_sort_range(a: &mut [usize], lo: usize, hi: usize, depth: usize) {
    if hi <= lo {
        return;
    }
    if hi - lo < 16 {
        insertion_sort(&mut a[lo..=hi]);
        return;
    }
    if depth == 0 {
        heap_sort(&mut a[lo..=hi]);
        return;
    }
    let p = partition(a, lo, hi);
    if p > 0 {
        intro_sort_range(a, lo, p - 1, depth - 1);
    }
    intro_sort_range(a, p + 1, hi, depth - 1);
}

fn intro_sort(a: &mut [usize]) {
    if let Some(hi) = a.len().checked_sub(1) {
        let depth = usize::BITS as usize - a.len().leading_zeros() as usize;
        intro_sort_range(a, 0, hi, depth * 2);
    }
}
{%- endif %}

{%- if sort_algorithm == "shell" %}
fn shell_sort(a: &mut [usize]) {
    let mut gap = a.len() / 2;
    while gap > 0 {
        for i in gap..a.len() {
            let x = a[i];
            let mut j = i;
            while j >= gap && a[j - gap] > x {
                a[j] = a[j - gap];
                j -= gap;
            }
            a[j] = x;
        }
        gap /= 2;
    }
}
{%- endif %}

{%- if sort_algorithm == "shaker" %}
fn shaker_sort(a: &mut [usize]) {
    if a.len() <= 1 {
        return;
    }
    let mut left = 0;
    let mut right = a.len() - 1;
    while left < right {
        let mut swapped = false;
        for i in left..right {
            if a[i] > a[i + 1] {
                a.swap(i, i + 1);
                swapped = true;
            }
        }
        if !swapped {
            break;
        }
        right -= 1;
        swapped = false;
        for i in (left + 1..=right).rev() {
            if a[i - 1] > a[i] {
                a.swap(i - 1, i);
                swapped = true;
            }
        }
        if !swapped {
            break;
        }
        left += 1;
    }
}
{%- endif %}

{%- if sort_algorithm == "comb" %}
fn comb_sort(a: &mut [usize]) {
    let mut gap = a.len();
    let mut swapped = true;
    while gap > 1 || swapped {
        gap = (gap * 10 / 13).max(1);
        swapped = false;
        for i in 0..a.len().saturating_sub(gap) {
            if a[i] > a[i + gap] {
                a.swap(i, i + gap);
                swapped = true;
            }
        }
    }
}
{%- endif %}

{%- if sort_algorithm == "gnome" %}
fn gnome_sort(a: &mut [usize]) {
    let mut i = 1;
    while i < a.len() {
        if i == 0 || a[i - 1] <= a[i] {
            i += 1;
        } else {
            a.swap(i - 1, i);
            i -= 1;
        }
    }
}
{%- endif %}

{%- if sort_algorithm == "selection" %}
fn selection_sort(a: &mut [usize]) {
    for i in 0..a.len() {
        let mut min = i;
        for j in i + 1..a.len() {
            if a[j] < a[min] {
                min = j;
            }
        }
        a.swap(i, min);
    }
}
{%- endif %}

{%- if sort_algorithm == "cycle" %}
fn cycle_sort(a: &mut [usize]) {
    let n = a.len();
    for cycle_start in 0..n.saturating_sub(1) {
        let mut item = a[cycle_start];
        let mut pos = cycle_start;
        for i in cycle_start + 1..n {
            if a[i] < item {
                pos += 1;
            }
        }
        if pos == cycle_start {
            continue;
        }
        while pos < n && a[pos] == item {
            pos += 1;
        }
        std::mem::swap(&mut a[pos], &mut item);
        while pos != cycle_start {
            pos = cycle_start;
            for i in cycle_start + 1..n {
                if a[i] < item {
                    pos += 1;
                }
            }
            while pos < n && a[pos] == item {
                pos += 1;
            }
            std::mem::swap(&mut a[pos], &mut item);
        }
    }
}
{%- endif %}

{%- if sort_algorithm == "tree" %}
#[derive(Default)]
struct Node {
    value: usize,
    count: usize,
    left: Option<Box<Node>>,
    right: Option<Box<Node>>,
}

fn insert_node(root: &mut Option<Box<Node>>, value: usize) {
    match root {
        Some(node) if value < node.value => insert_node(&mut node.left, value),
        Some(node) if value > node.value => insert_node(&mut node.right, value),
        Some(node) => node.count += 1,
        None => {
            *root = Some(Box::new(Node {
                value,
                count: 1,
                left: None,
                right: None,
            }));
        }
    }
}

fn drain_node(root: &Option<Box<Node>>, out: &mut Vec<usize>) {
    if let Some(node) = root {
        drain_node(&node.left, out);
        out.extend(std::iter::repeat(node.value).take(node.count));
        drain_node(&node.right, out);
    }
}

fn tree_sort(a: &mut [usize]) {
    let mut root = None;
    for &value in a.iter() {
        insert_node(&mut root, value);
    }
    let mut out = Vec::with_capacity(a.len());
    drain_node(&root, &mut out);
    a.copy_from_slice(&out);
}
{%- endif %}

{%- if sort_algorithm == "library" %}
fn library_sort(a: &mut [usize]) {
    let mut shelf: Vec<usize> = Vec::with_capacity(a.len());
    for &value in a.iter() {
        let pos = shelf.binary_search(&value).unwrap_or_else(|pos| pos);
        shelf.insert(pos, value);
    }
    a.copy_from_slice(&shelf);
}
{%- endif %}

{%- if sort_algorithm == "pancake" %}
fn flip_prefix(a: &mut [usize], end: usize) {
    let mut lo = 0;
    let mut hi = end;
    while lo < hi {
        a.swap(lo, hi);
        lo += 1;
        hi -= 1;
    }
}

fn pancake_sort(a: &mut [usize]) {
    let n = a.len();
    for size in (2..=n).rev() {
        let mut max_idx = 0;
        for i in 1..size {
            if a[i] > a[max_idx] {
                max_idx = i;
            }
        }
        if max_idx != size - 1 {
            if max_idx != 0 {
                flip_prefix(a, max_idx);
            }
            flip_prefix(a, size - 1);
        }
    }
}
{%- endif %}

{%- if sort_algorithm == "patience" %}
fn patience_sort(a: &mut [usize]) {
    let mut piles: Vec<Vec<usize>> = Vec::new();
    for &value in a.iter() {
        let mut lo = 0;
        let mut hi = piles.len();
        while lo < hi {
            let mid = (lo + hi) / 2;
            if *piles[mid].last().unwrap() >= value {
                hi = mid;
            } else {
                lo = mid + 1;
            }
        }
        if lo == piles.len() {
            piles.push(vec![value]);
        } else {
            piles[lo].push(value);
        }
    }
    for slot in a.iter_mut() {
        let mut min = 0;
        for i in 1..piles.len() {
            if piles[i].last().is_some()
                && (piles[min].last().is_none()
                    || piles[i].last().unwrap() < piles[min].last().unwrap())
            {
                min = i;
            }
        }
        *slot = piles[min].pop().unwrap();
    }
}
{%- endif %}

{%- if needs_merge_values %}
fn merge_values(left: &[usize], right: &[usize]) -> Vec<usize> {
    let mut out = Vec::with_capacity(left.len() + right.len());
    let (mut l, mut r) = (0, 0);
    while l < left.len() && r < right.len() {
        if left[l] <= right[r] {
            out.push(left[l]);
            l += 1;
        } else {
            out.push(right[r]);
            r += 1;
        }
    }
    out.extend_from_slice(&left[l..]);
    out.extend_from_slice(&right[r..]);
    out
}
{%- endif %}

{%- if sort_algorithm == "strand" %}
fn strand_sort(a: &mut [usize]) {
    let mut input = a.to_vec();
    let mut output = Vec::new();
    while !input.is_empty() {
        let mut strand = Vec::new();
        let mut rest = Vec::new();
        for value in input {
            if strand.last().map_or(true, |last| *last <= value) {
                strand.push(value);
            } else {
                rest.push(value);
            }
        }
        output = merge_values(&output, &strand);
        input = rest;
    }
    a.copy_from_slice(&output);
}
{%- endif %}

{%- if sort_algorithm == "oddeven" %}
fn odd_even_sort(a: &mut [usize]) {
    let mut sorted = false;
    while !sorted {
        sorted = true;
        for i in (1..a.len()).step_by(2) {
            if a[i - 1] > a[i] {
                a.swap(i - 1, i);
                sorted = false;
            }
        }
        for i in (2..a.len()).step_by(2) {
            if a[i - 1] > a[i] {
                a.swap(i - 1, i);
                sorted = false;
            }
        }
    }
}
{%- endif %}

{%- if sort_algorithm == "proportion_extend" %}
fn pe_sort_range(a: &mut [usize], lo: usize, hi: usize) {
    const P: usize = 16;
    if hi <= lo {
        return;
    }
    if hi - lo < 16 {
        insertion_sort(&mut a[lo..=hi]);
        return;
    }
    let mut s_end = lo;
    while s_end < hi && hi - s_end > P * (s_end - lo + 1) {
        let chunk_end = (s_end + P * (s_end - lo + 1)).min(hi);
        pe_sort_range(a, lo, chunk_end);
        s_end = chunk_end;
    }
    let median = lo + (s_end - lo) / 2;
    let pivot = partition_at(a, lo, hi, median);
    if pivot > 0 {
        pe_sort_range(a, lo, pivot - 1);
    }
    pe_sort_range(a, pivot + 1, hi);
}

fn proportion_extend_sort(a: &mut [usize]) {
    if let Some(hi) = a.len().checked_sub(1) {
        pe_sort_range(a, 0, hi);
    }
}
{%- endif %}

{%- if sort_algorithm == "sample" %}
fn sample_sort(a: &mut [usize]) {
    if a.len() <= 32 {
        insertion_sort(a);
        return;
    }
    let sample_count = (a.len() as f64).sqrt() as usize;
    let step = (a.len() / sample_count.max(1)).max(1);
    let mut splitters: Vec<usize> = (step - 1..a.len())
        .step_by(step)
        .take(sample_count)
        .map(|i| a[i])
        .collect();
    quick_sort(&mut splitters);
    let mut buckets = vec![Vec::new(); splitters.len() + 1];
    for &value in a.iter() {
        let bucket = splitters.partition_point(|&splitter| value > splitter);
        buckets[bucket].push(value);
    }
    let mut pos = 0;
    for bucket in buckets.iter_mut() {
        sample_sort(bucket);
        for &value in bucket.iter() {
            a[pos] = value;
            pos += 1;
        }
    }
}
{%- endif %}

{%- if sort_algorithm == "symmetry_partition" %}
fn sp_sort_range(a: &mut [usize], lo: usize, hi: usize) {
    const P: usize = 16;
    if hi <= lo {
        return;
    }
    if hi - lo < 16 {
        insertion_sort(&mut a[lo..=hi]);
        return;
    }
    let mut s_end = lo;
    while s_end < hi && hi - s_end > P * (s_end - lo + 1) {
        let chunk_end = (s_end + P * (s_end - lo + 1)).min(hi);
        sp_sort_range(a, lo, chunk_end);
        s_end = chunk_end;
    }
    let median = lo + (s_end - lo) / 2;
    let r_len = s_end - median;
    let r_start = median + 1;
    let r_dest = hi - r_len + 1;
    for i in 0..r_len {
        let from = r_start + i;
        let to = r_dest + i;
        if from != to {
            a.swap(from, to);
        }
    }
    let pivot = partition_at(a, lo, hi, median);
    if pivot > 0 {
        sp_sort_range(a, lo, pivot - 1);
    }
    sp_sort_range(a, pivot + 1, hi);
}

fn symmetry_partition_sort(a: &mut [usize]) {
    if let Some(hi) = a.len().checked_sub(1) {
        sp_sort_range(a, 0, hi);
    }
}
{%- endif %}

{%- if sort_algorithm == "cartesian_tree" %}
fn cartesian_tree_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    let mut left = vec![None; n];
    let mut right = vec![None; n];
    let mut stack = Vec::new();
    for i in 0..n {
        let mut last = None;
        while stack.last().is_some_and(|&top| a[top] > a[i]) {
            last = stack.pop();
        }
        if let Some(&top) = stack.last() {
            right[top] = Some(i);
        }
        if let Some(last_idx) = last {
            left[i] = Some(last_idx);
        }
        stack.push(i);
    }
    fn extract(
        node: Option<usize>,
        a: &[usize],
        left: &[Option<usize>],
        right: &[Option<usize>],
    ) -> Vec<usize> {
        if let Some(i) = node {
            let l = extract(left[i], a, left, right);
            let r = extract(right[i], a, left, right);
            let merged = merge_values(&l, &r);
            let mut out = Vec::with_capacity(merged.len() + 1);
            out.push(a[i]);
            out.extend(merged);
            out
        } else {
            Vec::new()
        }
    }
    let root = stack.first().copied();
    let out = extract(root, a, &left, &right);
    a.copy_from_slice(&out);
}
{%- endif %}

{%- if sort_algorithm == "tim" %}
fn tim_sort(a: &mut [usize]) {
    const MIN_RUN: usize = 32;
    let n = a.len();
    let mut runs = Vec::new();
    let mut i = 0;
    while i < n {
        let start = i;
        i += 1;
        if i < n && a[i - 1] > a[i] {
            while i < n && a[i - 1] > a[i] {
                i += 1;
            }
            a[start..i].reverse();
        } else {
            while i < n && a[i - 1] <= a[i] {
                i += 1;
            }
        }
        let end = (start + MIN_RUN).min(n).max(i);
        insertion_sort(&mut a[start..end]);
        runs.push((start, end));
        i = end;
    }
    while runs.len() > 1 {
        let mut next = Vec::new();
        for pair in runs.chunks(2) {
            if pair.len() == 1 {
                next.push(pair[0]);
                continue;
            }
            let (lo, mid) = pair[0];
            let (_, hi) = pair[1];
            let mut merged = Vec::with_capacity(hi - lo);
            let (mut l, mut r) = (lo, mid);
            while l < mid && r < hi {
                if a[l] <= a[r] {
                    merged.push(a[l]);
                    l += 1;
                } else {
                    merged.push(a[r]);
                    r += 1;
                }
            }
            merged.extend_from_slice(&a[l..mid]);
            merged.extend_from_slice(&a[r..hi]);
            a[lo..hi].copy_from_slice(&merged);
            next.push((lo, hi));
        }
        runs = next;
    }
}
{%- endif %}

{%- if sort_algorithm == "tournament" %}
fn tournament_winner(a: &[usize], left: usize, right: usize) -> usize {
    if left == usize::MAX {
        return right;
    }
    if right == usize::MAX {
        return left;
    }
    if a[left] <= a[right] {
        left
    } else {
        right
    }
}

fn tournament_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    let k = n.next_power_of_two();
    let mut tree = vec![0usize; 2 * k];
    for i in 0..k {
        tree[k + i] = if i < n { i } else { usize::MAX };
    }
    for i in (1..k).rev() {
        tree[i] = tournament_winner(a, tree[2 * i], tree[2 * i + 1]);
    }
    let mut out = vec![0usize; n];
    for pos in 0..n {
        let idx = tree[1];
        out[pos] = a[idx];
        a[idx] = usize::MAX;
        let mut node = k + idx;
        tree[node] = usize::MAX;
        while node > 1 {
            node /= 2;
            tree[node] = tournament_winner(a, tree[2 * node], tree[2 * node + 1]);
        }
    }
    a.copy_from_slice(&out);
}
{%- endif %}

{%- if sort_algorithm == "power" %}
#[derive(Clone, Copy)]
struct PowerRun {
    lo: usize,
    hi: usize,
    power: u32,
}

fn node_power(n: usize, b1: usize, e1: usize, b2: usize, e2: usize) -> u32 {
    let a = (b1 as f64 + (e1 - b1) as f64 / 2.0) / n as f64;
    let b = (b2 as f64 + (e2 - b2) as f64 / 2.0) / n as f64;
    let mut p = 0u32;
    while (a * 2f64.powi(p as i32)).floor() == (b * 2f64.powi(p as i32)).floor() {
        p += 1;
    }
    p
}

fn merge_power_runs(a: &mut [usize], left: PowerRun, right: PowerRun) -> PowerRun {
    let lo = left.lo;
    let hi = right.hi;
    let mid = left.hi + 1;
    let mut merged = Vec::with_capacity(hi - lo + 1);
    let (mut l, mut r) = (left.lo, mid);
    while l <= left.hi && r <= right.hi {
        if a[l] <= a[r] {
            merged.push(a[l]);
            l += 1;
        } else {
            merged.push(a[r]);
            r += 1;
        }
    }
    merged.extend_from_slice(&a[l..=left.hi]);
    merged.extend_from_slice(&a[r..=right.hi]);
    a[lo..=hi].copy_from_slice(&merged);
    PowerRun { lo, hi, power: 0 }
}

fn prepare_power_run(a: &mut [usize], start: usize, min_run: usize) -> usize {
    let n = a.len();
    let mut i = start + 1;
    if i < n && a[i - 1] > a[i] {
        while i < n && a[i - 1] > a[i] {
            i += 1;
        }
        a[start..i].reverse();
    } else {
        while i < n && a[i - 1] <= a[i] {
            i += 1;
        }
    }
    let end = (start + min_run).min(n).max(i);
    insertion_sort(&mut a[start..end]);
    end
}

fn power_sort(a: &mut [usize]) {
    const MIN_RUN: usize = 32;
    let n = a.len();
    if n <= 1 {
        return;
    }
    let mut stack: Vec<PowerRun> = Vec::new();
    let mut b1 = 0usize;
    let mut e1 = prepare_power_run(a, 0, MIN_RUN);
    while e1 < n {
        let b2 = e1;
        let e2 = prepare_power_run(a, b2, MIN_RUN);
        let p = node_power(n, b1, e1, b2, e2);
        while stack.last().is_some_and(|top| top.power > p) {
            let top = stack.pop().unwrap();
            let cur = PowerRun {
                lo: b1,
                hi: e1 - 1,
                power: 0,
            };
            let merged = merge_power_runs(a, top, cur);
            b1 = merged.lo;
            e1 = merged.hi + 1;
        }
        stack.push(PowerRun {
            lo: b1,
            hi: e1 - 1,
            power: p,
        });
        b1 = b2;
        e1 = e2;
    }
    while let Some(top) = stack.pop() {
        let cur = PowerRun {
            lo: b1,
            hi: e1 - 1,
            power: 0,
        };
        let merged = merge_power_runs(a, top, cur);
        b1 = merged.lo;
        e1 = merged.hi + 1;
    }
}
{%- endif %}

{%- if sort_algorithm == "smooth" %}
const LEONARDO: [usize; 46] = [
    1, 1, 3, 5, 9, 15, 25, 41, 67, 109, 177, 287, 465, 753, 1219, 1973, 3193,
    5167, 8361, 13529, 21891, 35421, 57313, 92735, 150049, 242785, 392835,
    635621, 1028457, 1664079, 2692537, 4356617, 7049155, 11405773, 18454929,
    29860703, 48315633, 78176337, 126491971, 204668309, 331160281, 535828591,
    866988873, 1402817465, 2269806339, 3672623805,
];

fn smooth_sift_in(a: &mut [usize], root_idx: usize, size: usize) {
    if size < 2 {
        return;
    }
    let tmp = a[root_idx];
    let mut root = root_idx;
    let mut sz = size;
    loop {
        let right = root - 1;
        let left = right - LEONARDO[sz - 2];
        let (next, next_size) = if a[right] < a[left] {
            (left, sz - 1)
        } else {
            (right, sz - 2)
        };
        if a[next] <= tmp {
            break;
        }
        a[root] = a[next];
        root = next;
        sz = next_size;
        if sz <= 1 {
            break;
        }
    }
    a[root] = tmp;
}

fn smooth_interheap_sift(a: &mut [usize], root_idx: usize, mask: usize, offset: usize) {
    let tmp = a[root_idx];
    let mut root = root_idx;
    let mut hmask = mask;
    let mut hoffset = offset;
    while hmask != 1 {
        let mut max = tmp;
        if hoffset > 1 {
            let right = root - 1;
            let left = right - LEONARDO[hoffset - 2];
            max = max.max(a[left]).max(a[right]);
        }
        let next = root - LEONARDO[hoffset];
        if a[next] <= max {
            break;
        }
        a[root] = a[next];
        root = next;
        loop {
            hmask >>= 1;
            hoffset += 1;
            if hmask & 1 != 0 {
                break;
            }
        }
    }
    a[root] = tmp;
    smooth_sift_in(a, root, hoffset);
}

fn smooth_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    let mut mask = 1usize;
    let mut offset = 1usize;
    for i in 1..n {
        if mask & 2 != 0 {
            mask = (mask >> 2) | 1;
            offset += 2;
        } else if offset == 1 {
            mask = (mask << 1) | 1;
            offset = 0;
        } else {
            mask = (mask << (offset - 1)) | 1;
            offset = 1;
        }
        let wide_bottom =
            (mask & 2 != 0 && i + 1 < n)
                || (offset > 0 && 1 + i + LEONARDO[offset - 1] < n);
        if wide_bottom {
            smooth_sift_in(a, i, offset);
        } else {
            smooth_interheap_sift(a, i, mask, offset);
        }
    }
    for i in (2..n).rev() {
        if offset < 2 {
            loop {
                mask >>= 1;
                offset += 1;
                if mask & 1 != 0 {
                    break;
                }
            }
        } else {
            let ch1 = i - 1;
            let ch0 = ch1 - LEONARDO[offset - 2];
            mask &= !1;
            for ch in [ch0, ch1] {
                mask = (mask << 1) | 1;
                offset -= 1;
                smooth_interheap_sift(a, ch, mask, offset);
            }
        }
    }
}
{%- endif %}

{%- if sort_algorithm == "bitonic" %}
fn compare_exchange(a: &mut [usize], i: usize, j: usize, dir_up: bool) {
    let swap = if dir_up {
        a[i] > a[j]
    } else {
        a[i] < a[j]
    };
    if swap {
        a.swap(i, j);
    }
}

fn bitonic_merge(a: &mut [usize], lo: usize, cnt: usize, dir_up: bool) {
    if cnt <= 1 {
        return;
    }
    let k = cnt / 2;
    for i in lo..lo + k {
        compare_exchange(a, i, i + k, dir_up);
    }
    bitonic_merge(a, lo, k, dir_up);
    bitonic_merge(a, lo + k, k, dir_up);
}

fn bitonic_sort_range(a: &mut [usize], lo: usize, cnt: usize, dir_up: bool) {
    if cnt <= 1 {
        return;
    }
    let k = cnt / 2;
    bitonic_sort_range(a, lo, k, true);
    bitonic_sort_range(a, lo + k, k, false);
    bitonic_merge(a, lo, cnt, dir_up);
}

fn bitonic_sort(a: &mut [usize]) {
    if a.is_empty() {
        return;
    }
    bitonic_sort_range(a, 0, a.len(), true);
}
{%- endif %}

{%- if sort_algorithm == "oddeven_merge" %}
fn odd_even_merge(a: &mut [usize], lo: usize, n: usize, r: usize) {
    let m = r * 2;
    if m < n {
        odd_even_merge(a, lo, n, m);
        odd_even_merge(a, lo + r, n, m);
        let mut i = lo + r;
        while i + r < lo + n {
            if a[i] > a[i + r] {
                a.swap(i, i + r);
            }
            i += m;
        }
    } else if lo + r < a.len() {
        if a[lo] > a[lo + r] {
            a.swap(lo, lo + r);
        }
    }
}

fn odd_even_merge_sort_range(a: &mut [usize], lo: usize, n: usize) {
    if n <= 1 {
        return;
    }
    let half = n / 2;
    odd_even_merge_sort_range(a, lo, half);
    odd_even_merge_sort_range(a, lo + half, half);
    odd_even_merge(a, lo, n, 1);
}

fn odd_even_merge_sort(a: &mut [usize]) {
    if a.is_empty() {
        return;
    }
    odd_even_merge_sort_range(a, 0, a.len());
}
{%- endif %}

{%- if sort_algorithm == "ford_johnson" %}
fn ford_johnson_insert_order(m: usize) -> Vec<usize> {
    if m == 0 {
        return Vec::new();
    }
    let mut js = vec![0usize, 1];
    while *js.last().unwrap() < m {
        let l = js.len();
        js.push(js[l - 1] + 2 * js[l - 2]);
    }
    let mut order = Vec::new();
    let mut used = vec![false; m];
    let mut prev_j = 0usize;
    for &j in js.iter().skip(1) {
        if j > m {
            break;
        }
        if j > prev_j {
            for idx in (prev_j..=j - 1).rev() {
                if idx < m && !used[idx] {
                    order.push(idx);
                    used[idx] = true;
                }
            }
            prev_j = j;
        }
    }
    for idx in (0..m).rev() {
        if !used[idx] {
            order.push(idx);
        }
    }
    order
}

fn ford_johnson_reorder_pairs(
    pairs: &[(usize, usize)],
    sorted_larges: &[usize],
) -> Vec<(usize, usize)> {
    let mut out = Vec::with_capacity(sorted_larges.len());
    let mut taken = vec![false; pairs.len()];
    for &lg in sorted_larges {
        for (i, p) in pairs.iter().enumerate() {
            if !taken[i] && p.1 == lg {
                out.push(*p);
                taken[i] = true;
                break;
            }
        }
    }
    out
}

fn ford_johnson(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    if n == 2 {
        if a[0] > a[1] {
            a.swap(0, 1);
        }
        return;
    }
    let pair_count = n / 2;
    let mut pairs: Vec<(usize, usize)> = Vec::with_capacity(pair_count);
    for i in 0..pair_count {
        let lo = 2 * i;
        let hi = lo + 1;
        if a[lo] > a[hi] {
            pairs.push((a[hi], a[lo]));
        } else {
            pairs.push((a[lo], a[hi]));
        }
    }
    let odd = if n % 2 == 1 { Some(a[n - 1]) } else { None };
    let mut larges: Vec<usize> = pairs.iter().map(|p| p.1).collect();
    ford_johnson(&mut larges);
    let sorted_pairs = ford_johnson_reorder_pairs(&pairs, &larges);
    let mut chain = Vec::with_capacity(n);
    chain.push(sorted_pairs[0].0);
    chain.extend(sorted_pairs.iter().map(|p| p.1));
    let mut pending_pairs: Vec<(usize, usize)> =
        sorted_pairs.iter().skip(1).copied().collect();
    if let Some(v) = odd {
        pending_pairs.push((v, usize::MAX));
    }
    let pending: Vec<usize> = pending_pairs.iter().map(|p| p.0).collect();
    for idx in ford_johnson_insert_order(pending.len()) {
        let val = pending[idx];
        let limit = if pending_pairs[idx].1 == usize::MAX {
            chain.len()
        } else {
            chain
                .iter()
                .position(|&x| x == pending_pairs[idx].1)
                .unwrap_or(chain.len())
        };
        let pos = chain[..limit].partition_point(|&x| x < val);
        chain.insert(pos, val);
    }
    a.copy_from_slice(&chain);
}
{%- endif %}

{%- if sort_algorithm == "shear" %}
fn shear_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    let side = (n as f64).sqrt().ceil() as usize;
    let mut grid = vec![usize::MAX; side * side];
    grid[..n].copy_from_slice(a);
    let phases = ((side as f64).log2().ceil() as usize + 1) * 2;
    for _ in 0..phases {
        for r in 0..side {
            let row = &mut grid[r * side..(r + 1) * side];
            insertion_sort(row);
            if r % 2 == 1 {
                row.reverse();
            }
        }
        for c in 0..side {
            let mut col: Vec<usize> = (0..side).map(|r| grid[r * side + c]).collect();
            insertion_sort(&mut col);
            for r in 0..side {
                grid[r * side + c] = col[r];
            }
        }
    }
    let mut out = Vec::with_capacity(n);
    for r in 0..side {
        if r % 2 == 0 {
            for c in 0..side {
                if grid[r * side + c] != usize::MAX {
                    out.push(grid[r * side + c]);
                }
            }
        } else {
            for c in (0..side).rev() {
                if grid[r * side + c] != usize::MAX {
                    out.push(grid[r * side + c]);
                }
            }
        }
    }
    a.copy_from_slice(&out);
}
{%- endif %}

{%- if sort_algorithm == "wiki" %}
const CACHE_SIZE: usize = 512;

#[derive(Clone, Copy)]
struct Range {
    start: usize,
    end: usize,
}

impl Range {
    fn new(start: usize, end: usize) -> Self {
        Self { start, end }
    }

    fn len(self) -> usize {
        self.end - self.start
    }
}

struct WikiIterator {
    size: usize,
    power_of_two: usize,
    numerator: usize,
    decimal: usize,
    denominator: usize,
    decimal_step: usize,
    numerator_step: usize,
}

impl WikiIterator {
    fn new(size: usize, min_level: usize) -> Self {
        let power_of_two = floor_power_of_two(size);
        let denominator = power_of_two / min_level;
        Self {
            size,
            power_of_two,
            numerator: 0,
            decimal: 0,
            denominator,
            decimal_step: size / denominator,
            numerator_step: size % denominator,
        }
    }

    fn begin(&mut self) {
        self.numerator = 0;
        self.decimal = 0;
    }

    fn next_range(&mut self) -> Range {
        let start = self.decimal;
        self.decimal += self.decimal_step;
        self.numerator += self.numerator_step;
        if self.numerator >= self.denominator {
            self.numerator -= self.denominator;
            self.decimal += 1;
        }
        Range::new(start, self.decimal)
    }

    fn finished(&self) -> bool {
        self.decimal >= self.size
    }

    fn next_level(&mut self) -> bool {
        self.decimal_step += self.decimal_step;
        self.numerator_step += self.numerator_step;
        if self.numerator_step >= self.denominator {
            self.numerator_step -= self.denominator;
            self.decimal_step += 1;
        }
        self.decimal_step < self.size
    }

    fn length(&self) -> usize {
        self.decimal_step
    }
}

fn floor_power_of_two(value: usize) -> usize {
    let mut x = value;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    #[cfg(target_pointer_width = "64")]
    {
        x |= x >> 32;
    }
    x - (x >> 1)
}

fn wiki_insertion_sort(a: &mut [usize], range: Range) {
    for i in range.start + 1..range.end {
        let temp = a[i];
        let mut j = i;
        while j > range.start && temp < a[j - 1] {
            a[j] = a[j - 1];
            j -= 1;
        }
        a[j] = temp;
    }
}

fn reverse(a: &mut [usize], range: Range) {
    let len = range.len();
    for index in (0..len / 2).rev() {
        a.swap(range.start + index, range.end - index - 1);
    }
}

fn rotate(a: &mut [usize], amount: usize, range: Range, cache: &mut [usize], cache_size: usize) {
    if range.len() == 0 {
        return;
    }
    let split = range.start + amount;
    let range1 = Range::new(range.start, split);
    let range2 = Range::new(split, range.end);
    if range1.len() <= range2.len() {
        if range1.len() <= cache_size {
            cache[..range1.len()].copy_from_slice(&a[range1.start..range1.end]);
            a.copy_within(range2.start..range2.end, range1.start);
            a[range1.start + range2.len()..range1.start + range2.len() + range1.len()]
                .copy_from_slice(&cache[..range1.len()]);
            return;
        }
    } else if range2.len() <= cache_size {
        cache[..range2.len()].copy_from_slice(&a[range2.start..range2.end]);
        a.copy_within(range1.start..range1.end, range2.end - range1.len());
        a[range1.start..range1.start + range2.len()].copy_from_slice(&cache[..range2.len()]);
        return;
    }
    reverse(a, range1);
    reverse(a, range2);
    reverse(a, range);
}

fn merge_into(from: &[usize], a: Range, b: Range, into: &mut [usize]) {
    let mut a_index = a.start;
    let mut b_index = b.start;
    let mut insert = 0;
    loop {
        if from[b_index] >= from[a_index] {
            into[insert] = from[a_index];
            a_index += 1;
            insert += 1;
            if a_index == a.end {
                into[insert..insert + b.end - b_index].copy_from_slice(&from[b_index..b.end]);
                break;
            }
        } else {
            into[insert] = from[b_index];
            b_index += 1;
            insert += 1;
            if b_index == b.end {
                into[insert..insert + a.end - a_index].copy_from_slice(&from[a_index..a.end]);
                break;
            }
        }
    }
}

fn merge_external(a: &mut [usize], a_range: Range, b: Range, cache: &mut [usize]) {
    cache[..a_range.len()].copy_from_slice(&a[a_range.start..a_range.end]);
    let mut a_index = 0;
    let mut b_index = b.start;
    let mut insert = a_range.start;
    let a_last = a_range.len();
    let b_last = b.end;
    if b.len() > 0 && a_range.len() > 0 {
        loop {
            if a[b_index] >= cache[a_index] {
                a[insert] = cache[a_index];
                a_index += 1;
                insert += 1;
                if a_index == a_last {
                    break;
                }
            } else {
                a[insert] = a[b_index];
                b_index += 1;
                insert += 1;
                if b_index == b_last {
                    break;
                }
            }
        }
    }
    a[insert..insert + a_last - a_index].copy_from_slice(&cache[a_index..a_last]);
}

fn merge_pair(
    a: &mut [usize],
    a_range: Range,
    b: Range,
    cache: &mut [usize],
    cache_size: usize,
) {
    if a[b.end - 1] < a[a_range.start] {
        rotate(
            a,
            a_range.len(),
            Range::new(a_range.start, b.end),
            cache,
            cache_size,
        );
    } else if a[b.start] < a[a_range.end - 1] {
        if a_range.len() + b.len() <= cache_size {
            cache[..a_range.len()].copy_from_slice(&a[a_range.start..a_range.end]);
            merge_external(a, a_range, b, cache);
        } else {
            let mut merged = Vec::with_capacity(a_range.len() + b.len());
            let (mut i, mut j) = (a_range.start, b.start);
            while i < a_range.end && j < b.end {
                if a[i] <= a[j] {
                    merged.push(a[i]);
                    i += 1;
                } else {
                    merged.push(a[j]);
                    j += 1;
                }
            }
            merged.extend_from_slice(&a[i..a_range.end]);
            merged.extend_from_slice(&a[j..b.end]);
            a[a_range.start..b.end].copy_from_slice(&merged);
        }
    }
}

fn wiki_sort(a: &mut [usize]) {
    let size = a.len();
    let mut cache = [0usize; CACHE_SIZE];
    let cache_size = CACHE_SIZE;

    if size < 4 {
        if size == 3 {
            if a[1] < a[0] {
                a.swap(0, 1);
            }
            if a[2] < a[1] {
                a.swap(1, 2);
                if a[1] < a[0] {
                    a.swap(0, 1);
                }
            }
        } else if size == 2 && a[1] < a[0] {
            a.swap(0, 1);
        }
        return;
    }

    let mut iterator = WikiIterator::new(size, 4);
    iterator.begin();
    while !iterator.finished() {
        let range = iterator.next_range();
        wiki_insertion_sort(a, range);
    }
    if size < 8 {
        return;
    }

    loop {
        if iterator.length() < cache_size {
            if (iterator.length() + 1) * 4 <= cache_size && iterator.length() * 4 <= size {
                iterator.begin();
                while !iterator.finished() {
                    let a1 = iterator.next_range();
                    let b1 = iterator.next_range();
                    let a2 = iterator.next_range();
                    let b2 = iterator.next_range();
                    let mut merged1_len = 0usize;
                    let mut merged2_len = 0usize;
                    if a[b1.end - 1] < a[a1.start] {
                        cache[b1.len()..b1.len() + a1.len()].copy_from_slice(&a[a1.start..a1.end]);
                        cache[..b1.len()].copy_from_slice(&a[b1.start..b1.end]);
                        merged1_len = a1.len() + b1.len();
                    } else if a[b1.start] < a[a1.end - 1] {
                        merge_into(a, a1, b1, &mut cache);
                        merged1_len = a1.len() + b1.len();
                    } else if !(a[b2.start] < a[a2.end - 1]) && !(a[a2.start] < a[b1.end - 1]) {
                        continue;
                    } else {
                        cache[..a1.len()].copy_from_slice(&a[a1.start..a1.end]);
                        cache[a1.len()..a1.len() + b1.len()].copy_from_slice(&a[b1.start..b1.end]);
                        merged1_len = a1.len() + b1.len();
                    }
                    let a1 = Range::new(a1.start, b1.end);
                    if a[b2.end - 1] < a[a2.start] {
                        cache[merged1_len + b2.len()..merged1_len + b2.len() + a2.len()]
                            .copy_from_slice(&a[a2.start..a2.end]);
                        cache[merged1_len..merged1_len + b2.len()].copy_from_slice(&a[b2.start..b2.end]);
                        merged2_len = a2.len() + b2.len();
                    } else if a[b2.start] < a[a2.end - 1] {
                        merge_into(a, a2, b2, &mut cache[merged1_len..]);
                        merged2_len = a2.len() + b2.len();
                    } else {
                        cache[merged1_len..merged1_len + a2.len()].copy_from_slice(&a[a2.start..a2.end]);
                        cache[merged1_len + a2.len()..merged1_len + a2.len() + b2.len()]
                            .copy_from_slice(&a[b2.start..b2.end]);
                        merged2_len = a2.len() + b2.len();
                    }
                    let a2 = Range::new(a2.start, b2.end);
                    let a3 = Range::new(0, merged1_len);
                    let b3 = Range::new(merged1_len, merged1_len + merged2_len);
                    if cache[b3.end - 1] < cache[a3.start] {
                        a[a1.start + merged2_len..a1.start + merged2_len + merged1_len]
                            .copy_from_slice(&cache[a3.start..a3.end]);
                        a[a1.start..a1.start + merged2_len].copy_from_slice(&cache[b3.start..b3.end]);
                    } else if cache[b3.start] < cache[a3.end - 1] {
                        merge_into(&cache, a3, b3, &mut a[a1.start..a1.start + merged1_len + merged2_len]);
                    } else {
                        a[a1.start..a1.start + merged1_len].copy_from_slice(&cache[a3.start..a3.end]);
                        a[a1.start + merged1_len..a1.start + merged1_len + merged2_len]
                            .copy_from_slice(&cache[b3.start..b3.end]);
                    }
                }
                iterator.next_level();
            } else {
                iterator.begin();
                while !iterator.finished() {
                    let a_range = iterator.next_range();
                    let b = iterator.next_range();
                    merge_pair(a, a_range, b, &mut cache, cache_size);
                }
            }
        } else {
            iterator.begin();
            while !iterator.finished() {
                let a_range = iterator.next_range();
                let b = iterator.next_range();
                merge_pair(a, a_range, b, &mut cache, cache_size);
            }
        }
        if !iterator.next_level() {
            break;
        }
    }
}
{%- endif %}

{%- if sort_algorithm == "grail" %}
pub trait Sortable: Ord + Copy {}
impl<T: Ord + Copy> Sortable for T {}

use std::cmp::Ordering;
use Ordering::*;

/*
 * MIT License
 *
 * Copyright (c) 2013 Andrey Astrelin
 * Copyright (c) 2020 <name-of-holy-grail-project>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/*
 * The Holy Grail Sort Project
 * Project Manager:      Summer Dragonfly
 * Project Contributors: 666666t
 *                       Anonymous0726
 *                       aphitorite
 *                       dani_dlg
 *                       EilrahcF
 *                       Enver
 *                       lovebuny
 *                       MP
 *                       phoenixbound
 *                       thatsOven
 *
 * Special thanks to "The Studio" Discord community!
 */

#[derive(PartialEq)]
enum Subarray {
    Right,
    Left,
}

const STATIC_SIZE: usize = 4096;

#[allow(dead_code)]
fn grail_sort_generic_unused<T: Sortable>(set: &mut [T], len: usize) {
    grail_common_sort(set, 0, len, &mut None, |a, b| a.cmp(&b));
}

#[allow(dead_code)]
fn grail_sort_by_unused<T: Sortable, F: FnMut(&T, &T) -> Ordering>(set: &mut [T], len: usize, cmp: F) {
    grail_common_sort(set, 0, len, &mut None, cmp);
}

#[allow(dead_code)]
fn grail_sort_with_static_buffer<T: Sortable + Default>(set: &mut [T], len: usize) {
    let mut buffer = vec![T::default(); STATIC_SIZE];
    let mut container = Some(&mut buffer[..]);

    grail_common_sort(set, 0, len, &mut container, |a, b| a.cmp(&b));
}

#[allow(dead_code)]
fn grail_sort_by_with_static_buffer_unused<T: Sortable + Default, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    len: usize,
    cmp: F,
) {
    let mut buffer = vec![T::default(); STATIC_SIZE];
    let mut container = Some(&mut buffer[..]);

    grail_common_sort(set, 0, len, &mut container, cmp);
}

#[allow(dead_code)]
fn grail_sort_with_dynamic_buffer_unused<T: Sortable + Default>(set: &mut [T], len: usize) {
    let temp_len = (len as f64).sqrt() as usize;
    let mut buffer = vec![T::default(); temp_len];
    let mut container = Some(&mut buffer[..]);

    grail_common_sort(set, 0, len, &mut container, |a, b| a.cmp(&b));
}

#[allow(dead_code)]
fn grail_sort_by_with_dynamic_buffer_unused<T: Sortable + Default, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    len: usize,
    cmp: F,
) {
    let temp_len = (len as f64).sqrt() as usize;
    let mut buffer = vec![T::default(); temp_len];
    let mut container = Some(&mut buffer[..]);

    grail_common_sort(set, 0, len, &mut container, cmp);
}

fn grail_block_swap<T: Sortable>(set: &mut [T], point_a: usize, point_b: usize, block_len: usize) {
    for i in 0..block_len {
        set.swap(point_a + i, point_b + i);
    }
}

fn grail_rotate<T: Sortable>(
    set: &mut [T],
    mut start: usize,
    mut left_len: usize,
    mut right_len: usize,
) {
    while left_len > 0 && right_len > 0 {
        if left_len <= right_len {
            grail_block_swap(set, start, start + left_len, left_len);
            start += left_len;
            right_len -= left_len;
        } else {
            grail_block_swap(
                set,
                start + left_len - right_len,
                start + left_len,
                right_len,
            );
            left_len -= right_len;
        }
    }
}

fn grail_binary_search_left<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &[T],
    start: usize,
    length: usize,
    target: &T,
    cmp: &mut F,
) -> usize {
    let mut left = 0;
    let mut right = length;
    while left < right {
        let middle = left + ((right - left) / 2);
        if cmp(&set[start + middle], target) == Less {
            left = middle + 1;
        } else {
            right = middle;
        }
    }
    left
}

fn grail_binary_search_right<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &[T],
    start: usize,
    length: usize,
    target: &T,
    cmp: &mut F,
) -> usize {
    let mut left = 0;
    let mut right = length;
    while left < right {
        let middle = left + ((right - left) / 2);
        if cmp(&set[start + middle], target) == Greater {
            right = middle;
        } else {
            left = middle + 1;
        }
    }
    right
}

fn grail_collect_keys<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    start: usize,
    length: usize,
    ideal_keys: usize,
    cmp: &mut F,
) -> usize {
    let mut keys_found = 1;
    let mut first_key = 0;
    let mut current_key = 1;

    while current_key < length && keys_found < ideal_keys {
        let insert_pos = grail_binary_search_left(
            set,
            start + first_key,
            keys_found,
            &set[start + current_key],
            cmp,
        );

        if insert_pos == keys_found
            || cmp(
                &set[start + current_key],
                &set[start + first_key + insert_pos],
            ) != Equal
        {
            grail_rotate(
                set,
                start + first_key,
                keys_found,
                current_key - (first_key + keys_found),
            );

            first_key = current_key - keys_found;

            grail_rotate(
                set,
                start + first_key + insert_pos,
                keys_found - insert_pos,
                1,
            );

            keys_found += 1;
        }
        current_key += 1;
    }
    grail_rotate(set, start, first_key, keys_found);
    keys_found
}

fn grail_pairwise_swaps<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    start: usize,
    length: usize,
    cmp: &mut F,
) {
    let mut index = 1;
    while index < length {
        let left = start + index - 1;
        let right = start + index;

        if cmp(&set[left], &set[right]) == Greater {
            set.swap(left - 2, right);
            set.swap(right - 2, left);
        } else {
            set.swap(left - 2, left);
            set.swap(right - 2, right);
        }

        index += 2;
    }

    let left = start + index - 1;
    if left < start + length {
        set.swap(left - 2, left);
    }
}

fn grail_pairwise_writes<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    start: usize,
    length: usize,
    cmp: &mut F,
) {
    let mut index = 1;
    while index < length {
        let left = start + index - 1;
        let right = start + index;

        if cmp(&set[left], &set[right]) == Greater {
            set[left - 2] = set[right];
            set[right - 2] = set[left];
        } else {
            set[left - 2] = set[left];
            set[right - 2] = set[right];
        }

        index += 2;
    }

    let left = start + index - 1;
    if left < start + length {
        set[left - 2] = set[left];
    }
}

fn grail_block_select_sort<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    keys: usize,
    start: usize,
    mut median_key: usize,
    block_count: usize,
    block_len: usize,
    cmp: &mut F,
) -> usize {
    for block in 1..block_count {
        let left = block - 1;
        let mut right = left;

        for index in block..block_count {
            let compare = cmp(
                &set[start + (right * block_len)],
                &set[start + (index * block_len)],
            );
            if compare == Greater
                || compare == Equal && cmp(&set[keys + right], &set[keys + index]) == Greater
            {
                right = index;
            }
        }

        if right != left {
            grail_block_swap(
                set,
                start + (left * block_len),
                start + (right * block_len),
                block_len,
            );

            set.swap(keys + left, keys + right);

            if median_key == left {
                median_key = right;
            } else if median_key == right {
                median_key = left;
            }
        }
    }
    median_key
}

fn grail_merge_forwards<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    start: usize,
    left_len: usize,
    right_len: usize,
    buffer_offset: isize,
    cmp: &mut F,
) {
    let mut left = start;
    let middle = start + left_len;
    let mut right = middle;
    let end = middle + right_len;
    let mut buffer = (start as isize - buffer_offset) as usize;

    while right < end {
        if left == middle || cmp(&set[left], &set[right]) == Greater {
            set.swap(buffer, right);
            right += 1;
        } else {
            set.swap(buffer, left);
            left += 1;
        }
        buffer += 1;
    }

    if buffer != left {
        grail_block_swap(set, buffer, left, middle - left);
    }
}

fn grail_merge_backwards<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    start: usize,
    left_len: usize,
    right_len: usize,
    buffer_offset: isize,
    cmp: &mut F,
) {
    let mut left: isize = (start + left_len - 1) as isize;
    let middle = left as usize;
    let mut right = middle + right_len;
    let end = start;
    let mut buffer = (right as isize + buffer_offset) as usize;

    while left >= end as isize {
        if right == middle || cmp(&set[left as usize], &set[right]) == Greater {
            set.swap(buffer, left as usize);
            left -= 1;
        } else {
            set.swap(buffer, right);
            right -= 1;
        }
        buffer -= 1;
    }
    if right != buffer {
        while right > middle {
            set.swap(buffer, right);
            buffer -= 1;
            right -= 1;
        }
    }
}

fn grail_out_of_place_merge<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    start: usize,
    left_len: usize,
    right_len: usize,
    buffer_offset: isize,
    cmp: &mut F,
) {
    let mut left = start;
    let middle = start + left_len;
    let mut right = middle;
    let end = middle + right_len;
    let mut buffer = (start as isize - buffer_offset) as usize;

    while right < end {
        if left == middle || cmp(&set[left], &set[right]) == Greater {
            set[buffer] = set[right];
            right += 1;
        } else {
            set[buffer] = set[left];
            left += 1;
        }
        buffer += 1;
    }

    if buffer != left {
        while left < middle {
            set[buffer] = set[left];
            buffer += 1;
            left += 1;
        }
    }
}

fn grail_in_place_buffer_reset<T: Sortable>(
    set: &mut [T],
    start: usize,
    reset_len: usize,
    buffer_len: usize,
) {
    let mut index = start + reset_len - 1;
    while index >= start {
        set.swap(index, index - buffer_len);
        index -= 1;
    }
}

fn grail_out_of_place_buffer_reset<T: Sortable>(
    set: &mut [T],
    start: usize,
    reset_len: usize,
    buffer_len: usize,
) {
    let mut index = start + reset_len - 1;
    while index >= start {
        set[index] = set[index - buffer_len];
        index -= 1;
    }
}

fn grail_in_place_buffer_rewind<T: Sortable>(
    set: &mut [T],
    start: usize,
    mut left_overs: usize,
    mut buffer: usize,
) {
    while left_overs > start {
        buffer -= 1;
        left_overs -= 1;
        set.swap(buffer, left_overs);
    }
}

fn grail_out_of_place_buffer_rewind<T: Sortable>(
    set: &mut [T],
    start: usize,
    mut left_overs: usize,
    mut buffer: usize,
) {
    while left_overs > start {
        buffer -= 1;
        left_overs -= 1;
        set[buffer] = set[left_overs];
    }
}

fn grail_build_blocks<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    buffer: &mut Option<&mut [T]>,
    start: usize,
    length: usize,
    buffer_len: usize,
    cmp: &mut F,
) {
    match buffer {
        Some(buf) => {
            let extern_len = if buffer_len < buf.len() {
                buffer_len
            } else {
                let mut temp = 1;
                while (temp * 2) <= buf.len() {
                    temp *= 2;
                }
                temp
            };

            grail_build_out_of_place(set, buf, start, length, buffer_len, extern_len, cmp);
        }
        None => {
            grail_pairwise_swaps(set, start, length, cmp);
            grail_build_in_place(set, start - 2, length, 2, buffer_len, cmp);
        }
    }
}

fn grail_build_out_of_place<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    buffer: &mut [T],
    mut start: usize,
    length: usize,
    buffer_len: usize,
    extern_len: usize,
    cmp: &mut F,
) {
    buffer[0..extern_len].copy_from_slice(&set[start - extern_len..start]);

    grail_pairwise_writes(set, start, length, cmp);
    start -= 2;

    let mut merge_len = 2;
    while merge_len < extern_len {
        let mut merge_index = start;
        let both_merges = 2 * merge_len;
        let merge_end = start + length - both_merges;
        let buffer_offset: isize = merge_len as isize;

        while merge_index <= merge_end {
            grail_out_of_place_merge(set, merge_index, merge_len, merge_len, buffer_offset, cmp);
            merge_index += both_merges;
        }
        let left_over = length - (merge_index - start);

        if left_over > merge_len {
            grail_out_of_place_merge(
                set,
                merge_index,
                merge_len,
                left_over - merge_len,
                buffer_offset,
                cmp,
            );
        } else {
            //TODO: Might not be correct?
            for offset in 0..left_over {
                set[merge_index + offset - merge_len] = set[merge_index + offset];
            }
        }

        start -= merge_len;
        merge_len *= 2;
    }

    set[start + length..start + length + extern_len].copy_from_slice(&buffer[0..extern_len]);
    grail_build_in_place(set, start, length, merge_len, buffer_len, cmp);
}

fn grail_build_in_place<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    mut start: usize,
    length: usize,
    current_merge: usize,
    buffer_len: usize,
    cmp: &mut F,
) {
    let mut merge_len = current_merge;
    while merge_len < buffer_len {
        let mut merge_index = start;
        let both_merges = 2 * merge_len;
        let merge_end = start + length - both_merges;
        let buffer_offset: isize = merge_len as isize;

        while merge_index <= merge_end {
            grail_merge_forwards(set, merge_index, merge_len, merge_len, buffer_offset, cmp);
            merge_index += both_merges;
        }

        let left_over = length - (merge_index - start);

        if left_over > merge_len {
            grail_merge_forwards(
                set,
                merge_index,
                merge_len,
                left_over - merge_len,
                buffer_offset,
                cmp,
            );
        } else {
            grail_rotate(set, merge_index - merge_len, merge_len, left_over);
        }

        start -= merge_len;
        merge_len *= 2;
    }

    let both_merges = 2 * buffer_len;
    let final_block = length % both_merges;
    let final_offset = start + length - final_block;
    if final_block <= buffer_len {
        grail_rotate(set, final_offset, final_block, buffer_len);
    } else {
        grail_merge_backwards(
            set,
            final_offset,
            buffer_len,
            final_block - buffer_len,
            buffer_len as isize,
            cmp,
        );
    }

    let mut merge_index: isize = final_offset as isize - both_merges as isize;
    while merge_index >= start as isize {
        grail_merge_backwards(
            set,
            merge_index as usize,
            buffer_len,
            buffer_len,
            buffer_len as isize,
            cmp,
        );
        merge_index -= both_merges as isize;
    }
}

fn grail_count_left_blocks<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &[T],
    offset: usize,
    block_count: usize,
    block_len: usize,
    cmp: &mut F,
) -> usize {
    let mut left_blocks = 0;
    let first_right_block = offset + (block_count * block_len);
    let mut prev_left_block = first_right_block - block_len;

    while left_blocks < block_count && cmp(&set[first_right_block], &set[prev_left_block]) == Less {
        left_blocks += 1;
        prev_left_block -= block_len;
    }

    left_blocks
}

fn grail_get_subarray<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &[T],
    current_key: usize,
    median_key: usize,
    cmp: &mut F,
) -> Subarray {
    if cmp(&set[current_key], &set[median_key]) == Less {
        Subarray::Left
    } else {
        Subarray::Right
    }
}

fn grail_smart_merge_out_of_place<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    start: usize,
    left_len: &mut usize,
    left_origin: &mut Subarray,
    right_len: usize,
    buffer_offset: usize,
    cmp: &mut F,
) {
    let mut left = start;
    let middle = start + *left_len;
    let mut right = middle;
    let end = middle + right_len;
    let mut buffer = start - buffer_offset;

    if *left_origin == Subarray::Left {
        while left < middle && right < end {
            if cmp(&set[left], &set[right]) <= Equal {
                set[buffer] = set[left];
                left += 1;
            } else {
                set[buffer] = set[right];
                right += 1;
            }
            buffer += 1;
        }
    } else {
        while left < middle && right < end {
            if cmp(&set[left], &set[right]) == Less {
                set[buffer] = set[left];
                left += 1;
            } else {
                set[buffer] = set[right];
                right += 1;
            }
            buffer += 1;
        }
    }

    if left < middle {
        *left_len = middle - left;
        grail_out_of_place_buffer_rewind(set, left, middle, end);
    } else {
        *left_len = end - right;
        if *left_origin == Subarray::Left {
            *left_origin = Subarray::Right;
        } else {
            *left_origin = Subarray::Left;
        }
    }
}

fn grail_smart_merge<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    start: usize,
    left_len: &mut usize,
    left_origin: &mut Subarray,
    right_len: usize,
    buffer_offset: usize,
    cmp: &mut F,
) {
    let mut left = start;
    let middle = start + *left_len;
    let mut right = middle;
    let end = middle + right_len;
    let mut buffer = start - buffer_offset;

    if *left_origin == Subarray::Left {
        while left < middle && right < end {
            if cmp(&set[left], &set[right]) <= Equal {
                set.swap(buffer, left);
                left += 1;
            } else {
                set.swap(buffer, right);
                right += 1;
            }
            buffer += 1;
        }
    } else {
        while left < middle && right < end {
            if cmp(&set[left], &set[right]) == Less {
                set.swap(buffer, left);
                left += 1;
            } else {
                set.swap(buffer, right);
                right += 1;
            }
            buffer += 1;
        }
    }

    if left < middle {
        *left_len = middle - left;
        grail_in_place_buffer_rewind(set, left, middle, end);
    } else {
        *left_len = end - right;
        if *left_origin == Subarray::Left {
            *left_origin = Subarray::Right;
        } else {
            *left_origin = Subarray::Left;
        }
    }
}

fn grail_smart_lazy_merge<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    mut start: usize,
    left_len: &mut usize,
    left_origin: &mut Subarray,
    mut right_len: usize,
    cmp: &mut F,
) {
    if *left_origin == Subarray::Left {
        if cmp(&set[start + *left_len - 1], &set[start + *left_len]) == Greater {
            while *left_len != 0 {
                let insert_pos =
                    grail_binary_search_left(set, start + *left_len, right_len, &set[start], cmp);

                if insert_pos != 0 {
                    grail_rotate(set, start, *left_len, insert_pos);
                    start += insert_pos;
                    right_len -= insert_pos;
                }

                if right_len == 0 {
                    return;
                } else {
                    start += 1;
                    *left_len -= 1;
                    while *left_len != 0 && cmp(&set[start], &set[start + *left_len]) <= Equal {
                        start += 1;
                        *left_len -= 1;
                    }
                }
            }
        }
    } else {
        if cmp(&set[start + *left_len - 1], &set[start + *left_len]) >= Equal {
            while *left_len != 0 {
                let insert_pos =
                    grail_binary_search_right(set, start + *left_len, right_len, &set[start], cmp);

                if insert_pos != 0 {
                    grail_rotate(set, start, *left_len, insert_pos);
                    start += insert_pos;
                    right_len -= insert_pos;
                }

                if right_len == 0 {
                    return;
                } else {
                    start += 1;
                    *left_len -= 1;
                    while *left_len != 0 && cmp(&set[start], &set[start + *left_len]) == Less {
                        start += 1;
                        *left_len -= 1;
                    }
                }
            }
        }
    }

    *left_len = right_len;
    if *left_origin == Subarray::Left {
        *left_origin = Subarray::Right;
    } else {
        *left_origin = Subarray::Left;
    }
}

fn grail_merge_blocks_out_of_place<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    keys: usize,
    median_key: usize,
    start: usize,
    block_count: usize,
    block_len: usize,
    final_left_blocks: usize,
    final_len: usize,
    cmp: &mut F,
) {
    let mut current_block;
    let mut block_index = block_len;

    let mut current_block_len = block_len;
    let mut current_block_origin = grail_get_subarray(set, keys, median_key, cmp);

    for key_index in 1..block_count {
        current_block = block_index - current_block_len;

        let next_block_origin = grail_get_subarray(set, keys + key_index, median_key, cmp);

        if next_block_origin == current_block_origin {
            internal_array_copy(
                set,
                start + current_block,
                start + current_block - block_len,
                current_block_len,
            );
            current_block_len = block_len;
        } else {
            grail_smart_merge_out_of_place(
                set,
                start + current_block,
                &mut current_block_len,
                &mut current_block_origin,
                block_len,
                block_len,
                cmp,
            );
        }
        block_index += block_len;
    }

    current_block = block_index - current_block_len;

    if final_len != 0 {
        if current_block_origin == Subarray::Right {
            internal_array_copy(
                set,
                start + current_block,
                start + current_block - block_len,
                current_block_len,
            );
            current_block = block_index;

            current_block_len = block_len * final_left_blocks;
        } else {
            current_block_len += block_len * final_left_blocks;
        }

        grail_out_of_place_merge(
            set,
            start + current_block,
            current_block_len,
            final_len,
            block_len as isize,
            cmp,
        );
    } else {
        internal_array_copy(
            set,
            start + current_block,
            start + current_block - block_len,
            current_block_len,
        );
    }
}

fn internal_array_copy<T: Sortable>(
    set: &mut [T],
    src_position: usize,
    dest_position: usize,
    length: usize,
) {
    for i in 0..length {
        set[dest_position + i] = set[src_position + i];
    }
    //Generally optimized, using basic implementation here for clarity for now
}

fn grail_merge_blocks<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    keys: usize,
    median_key: usize,
    start: usize,
    block_count: usize,
    block_len: usize,
    final_left_blocks: usize,
    final_len: usize,
    cmp: &mut F,
) {
    let mut first_block: usize;
    let mut block_index: usize = block_len;
    let mut first_block_len: usize = block_len;
    let mut first_block_origin: Subarray = if cmp(&set[keys], &set[median_key]) == Less {
        Subarray::Left
    } else {
        Subarray::Right
    };

    for key_index in 1..block_count {
        first_block = block_index - first_block_len;

        let next_block_origin = if cmp(&set[keys + key_index], &set[median_key]) == Less {
            Subarray::Left
        } else {
            Subarray::Right
        };

        if next_block_origin == first_block_origin {
            grail_block_swap(
                set,
                start + first_block - block_len,
                start + first_block,
                first_block_len,
            );
            first_block_len = block_len;
        } else {
            grail_smart_merge(
                set,
                start + first_block,
                &mut first_block_len,
                &mut first_block_origin,
                block_len,
                block_len,
                cmp,
            );
        }

        block_index += block_len;
    }

    first_block = block_index - first_block_len;

    if final_len != 0 {
        if first_block_origin == Subarray::Right {
            grail_block_swap(
                set,
                start + first_block - block_len,
                start + first_block,
                first_block_len,
            );

            first_block = block_index;
            first_block_len = block_len * final_left_blocks;
        } else {
            first_block_len += block_len * final_left_blocks;
        }

        grail_merge_forwards(
            set,
            start + first_block,
            first_block_len,
            final_len,
            block_len as isize,
            cmp,
        );
    } else {
        grail_block_swap(
            set,
            start + first_block,
            start + first_block - block_len,
            first_block_len,
        );
    }
}

fn grail_lazy_merge_blocks<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    keys: usize,
    median_key: usize,
    start: usize,
    block_count: usize,
    block_len: usize,
    final_left_blocks: usize,
    final_len: usize,
    cmp: &mut F,
) {
    let mut first_block;
    let mut block_index = block_len;
    let mut first_block_len = block_len;

    let mut first_block_origin = if cmp(&set[keys], &set[median_key]) == Less {
        Subarray::Left
    } else {
        Subarray::Right
    };

    for key_index in 1..block_count {
        first_block = block_index - first_block_len;

        let next_block_origin = if cmp(&set[keys + key_index], &set[median_key]) == Less {
            Subarray::Left
        } else {
            Subarray::Right
        };

        if next_block_origin == first_block_origin {
            first_block_len = block_len;
        } else {
            grail_smart_lazy_merge(
                set,
                start + first_block,
                &mut first_block_len,
                &mut first_block_origin,
                block_len,
                cmp,
            );
        }

        block_index += block_len;
    }

    first_block = block_index - first_block_len;

    if final_len != 0 {
        if first_block_origin == Subarray::Right {
            first_block = block_index;
            first_block_len = block_len * final_left_blocks;
        } else {
            first_block_len += block_len * final_left_blocks;
        }

        grail_lazy_merge(set, start + first_block, first_block_len, final_len, cmp);
    }
}

fn grail_combine_blocks<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    buffer: &mut Option<&mut [T]>,
    keys: usize,
    start: usize,
    mut length: usize,
    subarray_len: usize,
    block_len: usize,
    scrolling_buffer: bool,
    cmp: &mut F,
) {
    let merge_count = length / (2 * subarray_len);
    let mut last_subarray = length - (2 * subarray_len * merge_count);
    if last_subarray <= subarray_len {
        length -= last_subarray;
        last_subarray = 0;
    }

    match buffer {
        Some(buf) => {
            if block_len <= buf.len() {
                grail_combine_out_of_place(
                    set,
                    buf,
                    keys,
                    start,
                    length,
                    subarray_len,
                    block_len,
                    merge_count,
                    last_subarray,
                    cmp,
                );
            } else {
                grail_combine_in_place(
                    set,
                    keys,
                    start,
                    length,
                    subarray_len,
                    block_len,
                    merge_count,
                    last_subarray,
                    scrolling_buffer,
                    cmp,
                );
            }
        }
        None => grail_combine_in_place(
            set,
            keys,
            start,
            length,
            subarray_len,
            block_len,
            merge_count,
            last_subarray,
            scrolling_buffer,
            cmp,
        ),
    }
}

fn grail_combine_out_of_place<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    buffer: &mut [T],
    keys: usize,
    start: usize,
    length: usize,
    subarray_len: usize,
    block_len: usize,
    merge_count: usize,
    last_subarray: usize,
    cmp: &mut F,
) {
    buffer[0..block_len].copy_from_slice(&set[start - block_len..start]);
    for merge_index in 0..merge_count {
        let offset = start + (merge_index * (2 * subarray_len));
        let block_count = (2 * subarray_len) / block_len;

        grail_insertion_sort(set, keys, block_count, cmp);

        let mut median_key = subarray_len / block_len;
        median_key =
            grail_block_select_sort(set, keys, offset, median_key, block_count, block_len, cmp);

        grail_merge_blocks_out_of_place(
            set,
            keys,
            keys + median_key,
            offset,
            block_count,
            block_len,
            0,
            0,
            cmp,
        );
    }

    if last_subarray != 0 {
        let offset = start + (merge_count * (2 * subarray_len));
        let right_blocks = last_subarray / block_len;

        grail_insertion_sort(set, keys, right_blocks + 1, cmp);

        let mut median_key = subarray_len / block_len;
        median_key =
            grail_block_select_sort(set, keys, offset, median_key, right_blocks, block_len, cmp);

        let last_fragment = last_subarray - (right_blocks * block_len);
        let left_blocks = if last_fragment != 0 {
            grail_count_left_blocks(set, offset, right_blocks, block_len, cmp)
        } else {
            0
        };

        let block_count = right_blocks - left_blocks;
        if block_count == 0 {
            let left_length = left_blocks * block_len;
            grail_out_of_place_merge(
                set,
                offset,
                left_length,
                last_fragment,
                block_len as isize,
                cmp,
            );
        } else {
            grail_merge_blocks_out_of_place(
                set,
                keys,
                keys + median_key,
                offset,
                block_count,
                block_len,
                left_blocks,
                last_fragment,
                cmp,
            );
        }
    }
    grail_out_of_place_buffer_reset(set, start, length, block_len);
    set[start - block_len..start].copy_from_slice(&buffer[0..block_len]);
}

fn grail_combine_in_place<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    keys: usize,
    start: usize,
    length: usize,
    subarray_len: usize,
    block_len: usize,
    merge_count: usize,
    last_subarray: usize,
    scrolling_buffer: bool,
    cmp: &mut F,
) {
    for merge_index in 0..merge_count {
        let offset = start + (merge_index * (2 * subarray_len));
        let block_count = (2 * subarray_len) / block_len;

        grail_insertion_sort(set, keys, block_count, cmp);

        let mut median_key = subarray_len / block_len;
        median_key =
            grail_block_select_sort(set, keys, offset, median_key, block_count, block_len, cmp);

        if scrolling_buffer {
            grail_merge_blocks(
                set,
                keys,
                keys + median_key,
                offset,
                block_count,
                block_len,
                0,
                0,
                cmp,
            );
        } else {
            grail_lazy_merge_blocks(
                set,
                keys,
                keys + median_key,
                offset,
                block_count,
                block_len,
                0,
                0,
                cmp,
            );
        }
    }

    if last_subarray != 0 {
        let offset = start + (merge_count * (2 * subarray_len));
        let right_blocks = last_subarray / block_len;

        grail_insertion_sort(set, keys, right_blocks + 1, cmp);

        let mut median_key = subarray_len / block_len;
        median_key =
            grail_block_select_sort(set, keys, offset, median_key, right_blocks, block_len, cmp);

        let last_fragment = last_subarray - (right_blocks * block_len);
        let left_blocks = if last_fragment != 0 {
            grail_count_left_blocks(set, offset, right_blocks, block_len, cmp)
        } else {
            0
        };

        let block_count = right_blocks - left_blocks;

        if block_count == 0 {
            let left_length = left_blocks * block_len;

            if scrolling_buffer {
                grail_merge_forwards(
                    set,
                    offset,
                    left_length,
                    last_fragment,
                    block_len as isize,
                    cmp,
                );
            } else {
                grail_lazy_merge(set, offset, left_length, last_fragment, cmp);
            }
        } else {
            if scrolling_buffer {
                grail_merge_blocks(
                    set,
                    keys,
                    keys + median_key,
                    offset,
                    block_count,
                    block_len,
                    left_blocks,
                    last_fragment,
                    cmp,
                );
            } else {
                grail_lazy_merge_blocks(
                    set,
                    keys,
                    keys + median_key,
                    offset,
                    block_count,
                    block_len,
                    left_blocks,
                    last_fragment,
                    cmp,
                );
            }
        }
    }

    if scrolling_buffer {
        grail_in_place_buffer_reset(set, start, length, block_len);
    }
}

fn grail_lazy_merge<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    mut start: usize,
    mut left_len: usize,
    mut right_len: usize,
    cmp: &mut F,
) {
    if left_len < right_len {
        while left_len != 0 {
            let insert_pos =
                grail_binary_search_left(set, start + left_len, right_len, &set[start], cmp);

            if insert_pos != 0 {
                grail_rotate(set, start, left_len, insert_pos);
                start += insert_pos;
                right_len -= insert_pos;
            }

            if right_len == 0 {
                break;
            } else {
                start += 1;
                left_len -= 1;
                while left_len != 0 && cmp(&set[start], &set[start + left_len]) <= Equal {
                    start += 1;
                    left_len -= 1;
                }
            }
        }
    } else {
        let mut end = start + left_len + right_len - 1;
        while right_len != 0 {
            let insert_pos = grail_binary_search_right(set, start, left_len, &set[end], cmp);

            if insert_pos != left_len {
                grail_rotate(set, start + insert_pos, left_len - insert_pos, right_len);
                end -= left_len - insert_pos;
                left_len = insert_pos;
            }

            if left_len == 0 {
                break;
            } else {
                let left_end = start + left_len - 1;
                end -= 1;
                right_len -= 1;
                while right_len != 0 && cmp(&set[left_end], &set[end]) <= Equal {
                    end -= 1;
                    right_len -= 1;
                }
            }
        }
    }
}

fn grail_lazy_stable_sort<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    start: usize,
    length: usize,
    cmp: &mut F,
) {
    let mut index = 1;
    while index < length {
        let left = start + index - 1;
        let right = start + index;

        if cmp(&set[left], &set[right]) == Greater {
            set.swap(left, right);
        }
        index += 2;
    }
    let mut merge_len = 2;
    while merge_len < length {
        let mut merge_index = 0;
        let merge_end = length - (2 * merge_len);

        while merge_index <= merge_end {
            grail_lazy_merge(set, start + merge_index, merge_len, merge_len, cmp);
            merge_index += 2 * merge_len;
        }

        let left_over = length - merge_index;
        if left_over > merge_len {
            grail_lazy_merge(
                set,
                start + merge_index,
                merge_len,
                left_over - merge_len,
                cmp,
            );
        }

        merge_len *= 2;
    }
}

fn grail_insertion_sort<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    start: usize,
    length: usize,
    cmp: &mut F,
) {
    for item in 1..length {
        let mut left: isize = (start + item - 1) as isize;
        let mut right: isize = (start + item) as isize;

        while left >= start as isize && cmp(&set[left as usize], &set[right as usize]) == Greater {
            set.swap(left as usize, right as usize);
            left -= 1;
            right -= 1;
        }
    }
}

fn calc_min_keys(num_keys: usize, mut block_keys_sum: usize) -> usize {
    let mut min_keys = 1;
    while min_keys < num_keys && block_keys_sum != 0 {
        min_keys *= 2;
        block_keys_sum /= 8;
    }
    min_keys
}

fn grail_common_sort<T: Sortable, F: FnMut(&T, &T) -> Ordering>(
    set: &mut [T],
    start: usize,
    length: usize,
    ext_buf: &mut Option<&mut [T]>,
    mut cmp: F,
) {
    if length < 16 {
        //Grail Sort can only function on lengths >= 16 elements,
        //any smaller arrays are insertion sorted instead.
        grail_insertion_sort(set, start, length, &mut cmp);
    } else {
        let mut block_len = 1;
        while block_len * block_len < length {
            block_len *= 2;
        }

        let mut key_len = ((length - 1) / block_len) + 1;

        let ideal_keys = key_len + block_len;

        let keys_found = grail_collect_keys(set, start, length, ideal_keys, &mut cmp);
        let ideal_buffer;
        if keys_found < ideal_keys {
            if keys_found < 4 {
                grail_lazy_stable_sort(set, start, length, &mut cmp);
                return;
            } else {
                key_len = block_len;
                block_len = 0;
                ideal_buffer = false;

                while key_len > keys_found {
                    key_len /= 2;
                }
            }
        } else {
            ideal_buffer = true;
        }

        let buffer_end = block_len + key_len;
        let mut subarray_len = if ideal_buffer { block_len } else { key_len };

        grail_build_blocks(
            set,
            ext_buf,
            start + buffer_end,
            length - buffer_end,
            subarray_len,
            &mut cmp,
        );

        while length - buffer_end > 2 * subarray_len {
            subarray_len *= 2;

            let mut current_block_len = block_len;
            let mut scrolling_buffer = ideal_buffer;

            if !ideal_buffer {
                let half_key_len = key_len / 2;
                if half_key_len * half_key_len >= 2 * subarray_len {
                    current_block_len = half_key_len;
                    scrolling_buffer = true;
                } else {
                    let block_keys_sum = (subarray_len * keys_found) / 2;
                    let min_keys = calc_min_keys(key_len, block_keys_sum);

                    current_block_len = (2 * subarray_len) / min_keys;
                }
            }
            grail_combine_blocks(
                set,
                ext_buf,
                start,
                start + buffer_end,
                length - buffer_end,
                subarray_len,
                current_block_len,
                scrolling_buffer,
                &mut cmp,
            );
        }
        grail_insertion_sort(set, start, buffer_end, &mut cmp);
        grail_lazy_merge(set, start, buffer_end, length - buffer_end, &mut cmp);
    }
}

fn grail_sort(a: &mut [usize]) {
    let len = a.len();
    if len == 0 {
        return;
    }
    grail_sort_with_static_buffer(a, len);
}

{%- endif %}

{%- if sort_algorithm == "kota" %}
fn kota_insertion_sort(a: &mut [usize], lo: usize, hi: usize) {
    for i in lo + 1..hi {
        let key = a[i];
        let mut j = i;
        while j > lo && a[j - 1] > key {
            a[j] = a[j - 1];
            j -= 1;
        }
        a[j] = key;
    }
}

fn kota_block_swap(a: &mut [usize], start: usize, block_len: usize, i: usize, j: usize) {
    let bi = start + i * block_len;
    let bj = start + j * block_len;
    for k in 0..block_len {
        a.swap(bi + k, bj + k);
    }
}

fn kota_block_select(a: &mut [usize], start: usize, block_count: usize, block_len: usize) {
    for i in 0..block_count {
        let mut min = i;
        for j in i + 1..block_count {
            if a[start + j * block_len] < a[start + min * block_len] {
                min = j;
            }
        }
        if min != i {
            kota_block_swap(a, start, block_len, i, min);
        }
    }
}

fn kota_merge_with_buffer(a: &mut [usize], lo: usize, mid: usize, hi: usize, buf: &mut Vec<usize>) {
    let left_len = mid - lo;
    buf.resize(left_len, 0);
    buf[..left_len].copy_from_slice(&a[lo..mid]);
    let mut i = 0usize;
    let mut j = mid;
    let mut k = lo;
    while i < left_len && j < hi {
        if buf[i] <= a[j] {
            a[k] = buf[i];
            i += 1;
        } else {
            a[k] = a[j];
            j += 1;
        }
        k += 1;
    }
    while i < left_len {
        a[k] = buf[i];
        i += 1;
        k += 1;
    }
}

fn kota_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }

    let run_size = 16usize;
    let block_len = (n as f64).sqrt() as usize;
    let block_len = block_len.max(1);

    if n < run_size {
        kota_insertion_sort(a, 0, n);
        return;
    }

    for start in (0..n).step_by(run_size) {
        let end = (start + run_size).min(n);
        kota_insertion_sort(a, start, end);
    }

    let mut merge_buf = Vec::new();
    let mut width = run_size;
    while width < n {
        for lo in (0..n).step_by(width * 2) {
            let mid = (lo + width).min(n);
            let hi = (lo + width * 2).min(n);
            if mid >= hi {
                continue;
            }
            kota_merge_with_buffer(a, lo, mid, hi, &mut merge_buf);
            let span = hi - lo;
            if span >= block_len * 2 {
                let block_count = span / block_len;
                kota_block_select(a, lo, block_count, block_len);
            }
        }
        width *= 2;
    }
}
{%- endif %}

fn benchmark_sort(array: &mut [usize]) {
{% case sort_algorithm %}
{% when "bubble" %}
    bubble_sort(array);
{% when "quick" %}
    quick_sort(array);
{% when "merge" %}
    merge_sort(array);
{% when "heap" %}
    heap_sort(array);
{% when "insertion" %}
    insertion_sort(array);
{% when "binary_insertion" %}
    binary_insertion_sort(array);
{% when "shell" %}
    shell_sort(array);
{% when "intro" %}
    intro_sort(array);
{% when "shaker" %}
    shaker_sort(array);
{% when "comb" %}
    comb_sort(array);
{% when "gnome" %}
    gnome_sort(array);
{% when "selection" %}
    selection_sort(array);
{% when "cycle" %}
    cycle_sort(array);
{% when "tree" %}
    tree_sort(array);
{% when "library" %}
    library_sort(array);
{% when "smooth" %}
    smooth_sort(array);
{% when "patience" %}
    patience_sort(array);
{% when "strand" %}
    strand_sort(array);
{% when "oddeven" %}
    odd_even_sort(array);
{% when "pancake" %}
    pancake_sort(array);
{% when "shear" %}
    shear_sort(array);
{% when "proportion_extend" %}
    proportion_extend_sort(array);
{% when "sample" %}
    sample_sort(array);
{% when "symmetry_partition" %}
    symmetry_partition_sort(array);
{% when "cartesian_tree" %}
    cartesian_tree_sort(array);
{% when "tim" %}
    tim_sort(array);
{% when "tournament" %}
    tournament_sort(array);
{% when "power" %}
    power_sort(array);
{% when "bitonic" %}
    bitonic_sort(array);
{% when "oddeven_merge" %}
    odd_even_merge_sort(array);
{% when "ford_johnson" %}
    ford_johnson(array);
{% when "wiki" %}
    wiki_sort(array);
{% when "grail" %}
    grail_sort(array);
{% when "kota" %}
    kota_sort(array);
{% else %}
    panic!("unknown algorithm: {{ sort_algorithm }}");
{% endcase %}
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

fn run_once(size: usize, seed: usize) -> (u128, usize) {
    let expected: Vec<usize> = (1..=size).collect();
    let mut array = shuffled(size, seed as u64);

    let start = Instant::now();

    benchmark_sort(&mut array);

    let elapsed = start.elapsed();

    if array != expected {
        panic!(
            "sort failed with seed {} for size {}",
            seed,
            size
        );
    }

    (micros(elapsed), memory_usage_kb())
}

fn run_child(args: &[String]) {
    let size = args[2].parse::<usize>().expect("invalid size");
    let seed = args[3].parse::<usize>().expect("invalid seed");
    let (elapsed_us, mem) = run_once(size, seed);
    println!("{} {}", elapsed_us, mem);
}

fn main() {
    let args: Vec<String> = env::args().collect();
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
docker run --rm --init rust-benchmark
```

</div>

</details>
