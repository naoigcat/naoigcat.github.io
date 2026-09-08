/// Educational stand-in for scandum's blitsort (rotate merge / rotate quick).
/// Production uses trinity rotations, monobound binary search, quadsort blocks,
/// and branchless partitioning; here those are replaced with clearer routines
/// and a fixed swap of `BLIT_SWAP` elements (default 512, as in the reference).

const BLIT_SWAP: usize = 512;
const BLIT_OUT: usize = 24;

fn blit_is_sorted(a: &[usize]) -> bool {
    a.windows(2).all(|w| w[0] <= w[1])
}

fn blit_is_reverse_sorted(a: &[usize]) -> bool {
    a.windows(2).all(|w| w[0] >= w[1])
}

fn blit_reverse(a: &mut [usize]) {
    let mut lo = 0;
    let mut hi = a.len();
    while lo + 1 < hi {
        hi -= 1;
        a.swap(lo, hi);
        lo += 1;
    }
}

fn blit_ordered_pairs(a: &[usize]) -> usize {
    a.windows(2).filter(|w| w[0] <= w[1]).count()
}

fn blit_median3_idx(a: &[usize], i: usize, j: usize, k: usize) -> usize {
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

fn blit_quasimedian9(a: &[usize]) -> usize {
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
    let m0 = blit_median3_idx(a, i0, i1, i2);
    let m1 = blit_median3_idx(a, i3, i4, i5);
    let m2 = blit_median3_idx(a, i6, i7, i8);
    a[blit_median3_idx(a, m0, m1, m2)]
}

/// Rotate `a` so the prefix of length `left` moves after the suffix.
/// Prefer a swap-assisted block move; otherwise fall back to three reverses
/// (educational stand-in for trinity / bridge rotations).
fn blit_rotate(a: &mut [usize], left: usize, swap: &mut [usize]) {
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
fn blit_lower_bound(hay: &[usize], needle: usize) -> usize {
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

fn blit_merge_with_swap(a: &mut [usize], mid: usize, swap: &mut [usize]) {
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

/// Merge two adjacent sorted runs `[0..left_len)` and `[left_len..left_len+right_len)`
/// by rotating around the left run's center until the pieces fit in `swap`.
fn blit_rotate_merge_block(
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
        blit_merge_with_swap(a, left_len, swap);
        return;
    }
    if left_len <= swap_cap {
        blit_merge_with_swap(a, left_len, swap);
        return;
    }
    if right_len <= swap_cap {
        // Partial backward merge: right run fits in swap.
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
    let left = blit_lower_bound(&a[left_len..total], center);
    let right = right_len - left;

    // Layout: [ lblock | rblock | left | right ]
    if left > 0 {
        blit_rotate(&mut a[lblock..lblock + rblock + left], rblock, swap);
        // Now: [ lblock | left | rblock | right ]
        blit_rotate_merge_block(a, lblock, left, swap);
        blit_rotate_merge_block(&mut a[lblock + left..total], rblock, right, swap);
    } else if right > 0 {
        blit_rotate_merge_block(&mut a[lblock..total], rblock, right, swap);
    }
}

fn blit_rotate_mergesort(a: &mut [usize], swap: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    let block0 = BLIT_OUT.min(swap.len()).max(1);
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
            blit_rotate_merge_block(&mut a[start..end], left_len, right_len, swap);
            start = end;
        }
        block = block.saturating_mul(2);
        if block == 0 {
            break;
        }
    }
}

/// Stable partition: keys `<= pivot` stay toward the front.
/// When the range exceeds the swap, recurse on halves and rotate the middle
/// so left parts gather contiguously (rotate quicksort's assembly step).
fn blit_stable_partition(a: &mut [usize], swap: &mut [usize], pivot: usize) -> usize {
    let n = a.len();
    let swap_cap = swap.len();
    if n == 0 {
        return 0;
    }
    if n > swap_cap {
        let h = n / 2;
        let l = blit_stable_partition(&mut a[..h], swap, pivot);
        let r = blit_stable_partition(&mut a[h..], swap, pivot);
        // Middle band `a[l..h]` holds the right half of the left partition
        // (`> pivot`); length `h - l`. Right partition contributed `r` left keys
        // at `a[h..h+r]`. Rotate that band of length `(h - l) + r` by `h - l`.
        blit_rotate(&mut a[l..h + r], h - l, swap);
        return l + r;
    }

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

/// Like `blit_stable_partition`, but left keys are strictly less than `pivot`.
/// Used for the equal-key second sweep so ranges larger than the fixed swap
/// still stay within that buffer via half-recursion and rotate.
fn blit_strict_partition(a: &mut [usize], swap: &mut [usize], pivot: usize) -> usize {
    let n = a.len();
    let swap_cap = swap.len();
    if n == 0 {
        return 0;
    }
    if n > swap_cap {
        let h = n / 2;
        let l = blit_strict_partition(&mut a[..h], swap, pivot);
        let r = blit_strict_partition(&mut a[h..], swap, pivot);
        blit_rotate(&mut a[l..h + r], h - l, swap);
        return l + r;
    }

    swap[..n].copy_from_slice(a);
    let mut left = 0usize;
    for i in 0..n {
        if swap[i] < pivot {
            left += 1;
        }
    }
    let mut l = 0usize;
    let mut r = left;
    for i in 0..n {
        let x = swap[i];
        if x < pivot {
            a[l] = x;
            l += 1;
        } else {
            a[r] = x;
            r += 1;
        }
    }
    left
}

fn blit_partition_sort(a: &mut [usize], swap: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    if n <= BLIT_OUT {
        insertion_sort(a);
        return;
    }

    let pivot = blit_quasimedian9(a);
    let left = blit_stable_partition(a, swap, pivot);
    let right = n - left;

    if right == 0 {
        // Second sweep: gather keys strictly less than pivot. When `n` exceeds
        // the fixed swap, recurse + rotate instead of copying the whole range.
        let lt = blit_strict_partition(a, swap, pivot);
        if lt > 1 {
            blit_partition_sort(&mut a[..lt], swap);
        }
        return;
    }

    let unbalanced = (left > 0 && left < n / 16) || (right > 0 && right < n / 16);
    if unbalanced {
        if left > 1 {
            blit_rotate_mergesort(&mut a[..left], swap);
        }
        if right > 1 {
            blit_rotate_mergesort(&mut a[left..], swap);
        }
        return;
    }

    if left > 1 {
        blit_partition_sort(&mut a[..left], swap);
    }
    if right > 1 {
        blit_partition_sort(&mut a[left..], swap);
    }
}

fn blit_analyze(a: &mut [usize], swap: &mut [usize]) -> bool {
    let n = a.len();
    if n <= 1 {
        return true;
    }
    if blit_is_sorted(a) {
        return true;
    }
    if blit_is_reverse_sorted(a) {
        blit_reverse(a);
        return true;
    }

    // Four-segment presortedness (flux / blit analyzer stand-in): finish
    // mostly-ordered quarters with rotate mergesort, then fall through to
    // rotate quicksort for remaining disorder.
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
            if blit_ordered_pairs(&a[lo..hi]) * 2 > pairs {
                blit_rotate_mergesort(&mut a[lo..hi], swap);
            }
        }
        if blit_is_sorted(a) {
            return true;
        }
    }
    false
}

fn blit_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    if n <= BLIT_OUT {
        insertion_sort(a);
        return;
    }
    let swap_len = BLIT_SWAP.min(n);
    let mut swap = vec![0usize; swap_len];
    if blit_analyze(a, &mut swap) {
        return;
    }
    blit_partition_sort(a, &mut swap);
}
