const FLUX_INSERTION_THRESHOLD: usize = 24;

fn flux_is_sorted(a: &[usize]) -> bool {
    a.windows(2).all(|w| w[0] <= w[1])
}

fn flux_is_reverse_sorted(a: &[usize]) -> bool {
    a.windows(2).all(|w| w[0] >= w[1])
}

fn flux_reverse(a: &mut [usize]) {
    let mut lo = 0;
    let mut hi = a.len();
    while lo + 1 < hi {
        hi -= 1;
        a.swap(lo, hi);
        lo += 1;
    }
}

/// Count ascending adjacent pairs (presortedness measure).
fn flux_ordered_pairs(a: &[usize]) -> usize {
    a.windows(2).filter(|w| w[0] <= w[1]).count()
}

fn flux_median3_idx(a: &[usize], i: usize, j: usize, k: usize) -> usize {
    let (x, y, z) = (a[i], a[j], a[k]);
    if x < y {
        if y < z {
            j
        } else if x < z {
            k
        } else {
            i
        }
    } else if x < z {
        i
    } else if y < z {
        k
    } else {
        j
    }
}

/// Quasimedian of 9: median of three medians-of-three sampled across the range.
fn flux_quasimedian9(a: &[usize]) -> usize {
    let n = a.len();
    if n < 9 {
        return a[n / 2];
    }
    let step = n / 8;
    let i0 = 0;
    let i1 = step;
    let i2 = step * 2;
    let i3 = step * 3;
    let i4 = step * 4;
    let i5 = step * 5;
    let i6 = step * 6;
    let i7 = step * 7;
    let i8 = n - 1;
    let m0 = flux_median3_idx(a, i0, i1, i2);
    let m1 = flux_median3_idx(a, i3, i4, i5);
    let m2 = flux_median3_idx(a, i6, i7, i8);
    a[flux_median3_idx(a, m0, m1, m2)]
}

fn flux_merge(a: &mut [usize], swap: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    let mid = n / 2;
    flux_merge(&mut a[..mid], swap);
    flux_merge(&mut a[mid..], swap);
    let (left, right) = a.split_at(mid);
    let mut i = 0;
    let mut j = 0;
    let mut k = 0;
    while i < left.len() && j < right.len() {
        if left[i] <= right[j] {
            swap[k] = left[i];
            i += 1;
        } else {
            swap[k] = right[j];
            j += 1;
        }
        k += 1;
    }
    while i < left.len() {
        swap[k] = left[i];
        i += 1;
        k += 1;
    }
    while j < right.len() {
        swap[k] = right[j];
        j += 1;
        k += 1;
    }
    a.copy_from_slice(&swap[..n]);
}

/// Stable dual-destination partition: `≤ pivot` stay toward the front of `a`,
/// `> pivot` are collected after them (educational stand-in for fluxsort’s
/// main/swap split). Returns the length of the left partition.
fn flux_stable_partition(a: &mut [usize], swap: &mut [usize], pivot: usize) -> usize {
    let n = a.len();
    swap[..n].copy_from_slice(a);
    let mut left = 0usize;
    for i in 0..n {
        if swap[i] <= pivot {
            left += 1;
        }
    }
    let mut l = 0usize;
    let mut r = left;
    for i in 0..n {
        let x = swap[i];
        if x <= pivot {
            a[l] = x;
            l += 1;
        } else {
            a[r] = x;
            r += 1;
        }
    }
    left
}

fn flux_partition_sort(a: &mut [usize], swap: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    if n < FLUX_INSERTION_THRESHOLD {
        insertion_sort(a);
        return;
    }

    let pivot = flux_quasimedian9(a);
    let left = flux_stable_partition(a, swap, pivot);
    let right = n - left;

    // All keys ≤ pivot: filter equals out so recursion makes progress
    // (fluxsort’s “second sweep” for generic / low-cardinality data).
    if right == 0 {
        swap[..n].copy_from_slice(a);
        let mut lt = 0usize;
        for i in 0..n {
            if swap[i] < pivot {
                a[lt] = swap[i];
                lt += 1;
            }
        }
        let mut eq = lt;
        for i in 0..n {
            if swap[i] == pivot {
                a[eq] = swap[i];
                eq += 1;
            }
        }
        if lt > 1 {
            flux_partition_sort(&mut a[..lt], swap);
        }
        return;
    }

    // Worst-case guard: one side < 1/16 of the other → mergesort both sides.
    let unbalanced = left > 0 && (left < n / 16 || right < n / 16);

    if unbalanced {
        flux_merge(&mut a[..left], swap);
        flux_merge(&mut a[left..], swap);
        return;
    }

    if left > 1 {
        flux_partition_sort(&mut a[..left], swap);
    }
    if right > 1 {
        flux_partition_sort(&mut a[left..], swap);
    }
}

fn flux_analyze(a: &mut [usize], swap: &mut [usize]) -> bool {
    let n = a.len();
    if n <= 1 {
        return true;
    }
    if flux_is_sorted(a) {
        return true;
    }
    if flux_is_reverse_sorted(a) {
        flux_reverse(a);
        return true;
    }

    // Four-segment presortedness: if more than half the adjacent pairs in a
    // segment are ordered, finish that segment with mergesort (stand-in for
    // quadsort). Remaining disorder is handled by partitioning afterward.
    let q = n / 4;
    if q >= 2 {
        let bounds = [0, q, q * 2, q * 3, n];
        for s in 0..4 {
            let lo = bounds[s];
            let hi = bounds[s + 1];
            if hi - lo < 2 {
                continue;
            }
            let pairs = hi - lo - 1;
            if flux_ordered_pairs(&a[lo..hi]) * 2 > pairs {
                flux_merge(&mut a[lo..hi], swap);
            }
        }
        if flux_is_sorted(a) {
            return true;
        }
    }
    false
}

fn flux_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    let mut swap = vec![0usize; n];
    if flux_analyze(a, &mut swap) {
        return;
    }
    flux_partition_sort(a, &mut swap);
}
