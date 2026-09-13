/// Educational stand-in for scandum's crumsort (fulcrum partition + rotate merge).
/// Production keeps a small fixed swap (≈512) with quadsort; here the merge
/// fallback uses that same fixed swap and rotation-based merging so auxiliary
/// memory stays O(1).

const CRUM_SWAP: usize = 512;
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

/// Rotate `a` so the prefix of length `left` moves after the suffix.
/// Prefer a swap-assisted block move; otherwise fall back to three reverses.
fn crum_rotate(a: &mut [usize], left: usize, swap: &mut [usize]) {
    let n = a.len();
    if left == 0 || left == n {
        return;
    }
    let right = n - left;
    let swap_cap = swap.len();

    if left <= right {
        if left <= swap_cap {
            swap[..left].copy_from_slice(&a[..left]);
            a.copy_within(left..n, 0);
            a[right..n].copy_from_slice(&swap[..left]);
            return;
        }
    } else if right <= swap_cap {
        swap[..right].copy_from_slice(&a[left..n]);
        a.copy_within(..left, right);
        a[..right].copy_from_slice(&swap[..right]);
        return;
    }

    a[..left].reverse();
    a[left..].reverse();
    a.reverse();
}

/// Lower bound: first index `i` in `hay` with `hay[i] >= needle`.
fn crum_lower_bound(hay: &[usize], needle: usize) -> usize {
    let mut lo = 0usize;
    let mut hi = hay.len();
    while lo < hi {
        let mid = lo + (hi - lo) / 2;
        if hay[mid] < needle {
            lo = mid + 1;
        } else {
            hi = mid;
        }
    }
    lo
}

fn crum_merge_with_swap(a: &mut [usize], mid: usize, swap: &mut [usize]) {
    let n = a.len();
    debug_assert!(mid <= n);
    debug_assert!(mid <= swap.len());
    swap[..mid].copy_from_slice(&a[..mid]);
    let mut i = 0usize;
    let mut j = mid;
    let mut k = 0usize;
    while i < mid && j < n {
        if swap[i] <= a[j] {
            a[k] = swap[i];
            i += 1;
        } else {
            a[k] = a[j];
            j += 1;
        }
        k += 1;
    }
    while i < mid {
        a[k] = swap[i];
        i += 1;
        k += 1;
    }
}

/// Merge two adjacent sorted runs by rotating around the left run's center
/// until the pieces fit in the fixed `swap`.
fn crum_rotate_merge_block(
    a: &mut [usize],
    left_len: usize,
    right_len: usize,
    swap: &mut [usize],
) {
    if left_len == 0 || right_len == 0 {
        return;
    }
    if a[left_len - 1] <= a[left_len] {
        return;
    }

    let total = left_len + right_len;
    let swap_cap = swap.len();
    if total <= swap_cap {
        crum_merge_with_swap(a, left_len, swap);
        return;
    }
    if left_len <= swap_cap {
        crum_merge_with_swap(a, left_len, swap);
        return;
    }
    if right_len <= swap_cap {
        swap[..right_len].copy_from_slice(&a[left_len..total]);
        let mut i = left_len;
        let mut j = right_len;
        let mut k = total;
        while i > 0 && j > 0 {
            if a[i - 1] > swap[j - 1] {
                k -= 1;
                i -= 1;
                a[k] = a[i];
            } else {
                k -= 1;
                j -= 1;
                a[k] = swap[j];
            }
        }
        while j > 0 {
            k -= 1;
            j -= 1;
            a[k] = swap[j];
        }
        return;
    }

    let rblock = left_len / 2;
    let lblock = left_len - rblock;
    let center = a[lblock];
    let left = crum_lower_bound(&a[left_len..total], center);
    let right = right_len - left;

    if left > 0 {
        crum_rotate(&mut a[lblock..lblock + rblock + left], rblock, swap);
        crum_rotate_merge_block(a, lblock, left, swap);
        crum_rotate_merge_block(&mut a[lblock + left..total], rblock, right, swap);
    } else if right > 0 {
        crum_rotate_merge_block(&mut a[lblock..total], rblock, right, swap);
    }
}

fn crum_rotate_mergesort(a: &mut [usize], swap: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    let block0 = CRUM_INSERTION_THRESHOLD.min(swap.len()).max(1);
    let mut i = 0usize;
    while i < n {
        let end = (i + block0).min(n);
        insertion_sort(&mut a[i..end]);
        i = end;
    }
    let mut block = block0;
    while block < n {
        let mut start = 0usize;
        while start < n {
            let mid = start + block;
            if mid >= n {
                break;
            }
            let end = (mid + block).min(n);
            let left_len = mid - start;
            let right_len = end - mid;
            crum_rotate_merge_block(&mut a[start..end], left_len, right_len, swap);
            start = end;
        }
        block = block.saturating_mul(2);
        if block == 0 {
            break;
        }
    }
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

    // Worst-case guard: one side < 1/16 of the other → rotate-mergesort both sides.
    let unbalanced = (left_len > 0 && left_len < n / 16)
        || (right_len > 0 && right_len < n / 16);

    if unbalanced {
        if left_len > 1 {
            crum_rotate_mergesort(&mut a[..left_len], swap);
        }
        if right_len > 1 {
            crum_rotate_mergesort(&mut a[mid + 1..], swap);
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
    // segment are ordered, finish that segment with rotate-mergesort (stand-in
    // for quadsort). Remaining disorder is handled by partitioning afterward.
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
                crum_rotate_mergesort(&mut a[lo..hi], swap);
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
    let mut swap = [0usize; CRUM_SWAP];
    if crum_analyze(a, &mut swap) {
        return;
    }
    crum_partition_sort(a, &mut swap);
}
