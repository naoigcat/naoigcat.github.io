<!-- markdownlint-disable MD041 -->
{% assign sort_algorithm = include.algorithm %}
{% assign sort_algorithm_key = sort_algorithm | prepend: "|" | append: "|" %}
{% assign insertion_sort_algorithms = "|insertion|quick|intro|proportion_extend|sample|symmetry_partition|tim|power|shear|" %}
{% assign partition_at_algorithms = "|quick|intro|proportion_extend|sample|symmetry_partition|" %}
{% assign partition_algorithms = "|quick|intro|sample|" %}
{% assign quick_sort_algorithms = "|quick|sample|" %}
{% assign heap_sort_algorithms = "|heap|intro|" %}
{% assign merge_values_algorithms = "|strand|cartesian_tree|" %}
{% assign quadratic_average_algorithms = "|bubble|insertion|shaker|gnome|selection|oddeven|cycle|pancake|ford_johnson|" %}
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
