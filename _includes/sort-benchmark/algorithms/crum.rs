const CRUM_INSERTION_THRESHOLD: usize = 24;

fn crum_is_sorted(a: &[usize]) -> bool {
    a.windows(2).all(|w| w[0] <= w[1])
}

fn crum_is_reverse_sorted(a: &[usize]) -> bool {
    a.windows(2).all(|w| w[0] >= w[1])
}

fn crum_reverse(a: &mut [usize]) {
    let mut lo = 0;
    let mut hi = a.len();
    while lo + 1 < hi {
        hi -= 1;
        a.swap(lo, hi);
        lo += 1;
    }
}

/// Count ascending adjacent pairs (presortedness measure).
fn crum_ordered_pairs(a: &[usize]) -> usize {
    a.windows(2).filter(|w| w[0] <= w[1]).count()
}

fn crum_median3_idx(a: &[usize], i: usize, j: usize, k: usize) -> usize {
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
fn crum_quasimedian9(a: &[usize]) -> usize {
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
    let m0 = crum_median3_idx(a, i0, i1, i2);
    let m1 = crum_median3_idx(a, i3, i4, i5);
    let m2 = crum_median3_idx(a, i6, i7, i8);
    a[crum_median3_idx(a, m0, m1, m2)]
}

fn crum_merge(a: &mut [usize], swap: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    let mid = n / 2;
    crum_merge(&mut a[..mid], swap);
    crum_merge(&mut a[mid..], swap);
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

/// Fulcrum partition: hold the pivot value in a one-element swap slot and walk
/// head/tail with two assignments per move (instead of a three-way swap).
/// Places a chosen `pivot` value at the split. Unstable. Returns its index.
fn crum_fulcrum_partition(a: &mut [usize], pivot: usize) -> usize {
    let n = a.len();
    debug_assert!(n >= 2);

    let mut pivot_idx = 0usize;
    for i in 0..n {
        if a[i] == pivot {
            pivot_idx = i;
            break;
        }
    }
    a.swap(0, pivot_idx);

    let pivot_val = a[0];
    let mut head = 0usize;
    let mut tail = n - 1;

    loop {
        while head < tail && a[tail] > pivot_val {
            tail -= 1;
        }
        if head >= tail {
            a[head] = pivot_val;
            return head;
        }
        a[head] = a[tail];
        head += 1;

        while head < tail && a[head] <= pivot_val {
            head += 1;
        }
        if head >= tail {
            a[head] = pivot_val;
            return head;
        }
        a[tail] = a[head];
        tail -= 1;
    }
}

fn crum_partition_sort(a: &mut [usize], swap: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    if n < CRUM_INSERTION_THRESHOLD {
        insertion_sort(a);
        return;
    }

    let pivot = crum_quasimedian9(a);
    let mid = crum_fulcrum_partition(a, pivot);
    let left_len = mid;
    let right_len = n - mid - 1;

    // All keys ≤ pivot: filter equals out so recursion makes progress
    // (crumsort’s reverse / second sweep for generic / low-cardinality data).
    if right_len == 0 {
        let mut lt = 0usize;
        for i in 0..n {
            if a[i] < pivot {
                a.swap(lt, i);
                lt += 1;
            }
        }
        if lt > 1 {
            crum_partition_sort(&mut a[..lt], swap);
        }
        return;
    }

    // Worst-case guard: one side < 1/16 of the other → mergesort both sides.
    let unbalanced = (left_len > 0 && left_len < n / 16)
        || (right_len > 0 && right_len < n / 16);

    if unbalanced {
        if left_len > 1 {
            crum_merge(&mut a[..left_len], swap);
        }
        if right_len > 1 {
            crum_merge(&mut a[mid + 1..], swap);
        }
        return;
    }

    if left_len > 1 {
        crum_partition_sort(&mut a[..left_len], swap);
    }
    if right_len > 1 {
        crum_partition_sort(&mut a[mid + 1..], swap);
    }
}

fn crum_analyze(a: &mut [usize], swap: &mut [usize]) -> bool {
    let n = a.len();
    if n <= 1 {
        return true;
    }
    if crum_is_sorted(a) {
        return true;
    }
    if crum_is_reverse_sorted(a) {
        crum_reverse(a);
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
            if crum_ordered_pairs(&a[lo..hi]) * 2 > pairs {
                crum_merge(&mut a[lo..hi], swap);
            }
        }
        if crum_is_sorted(a) {
            return true;
        }
    }
    false
}

fn crum_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    // Educational stand-in: merge fallback / analyzer share an O(n) buffer.
    // Production crumsort keeps a small fixed swap (≈512) with quadsort.
    let mut swap = vec![0usize; n];
    if crum_analyze(a, &mut swap) {
        return;
    }
    crum_partition_sort(a, &mut swap);
}
