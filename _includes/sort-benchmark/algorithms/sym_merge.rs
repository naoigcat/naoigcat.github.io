fn sym_swap_range(a: &mut [usize], left: usize, right: usize, n: usize) {
    for i in 0..n {
        a.swap(left + i, right + i);
    }
}

/// Rotate consecutive blocks `a[lo..mid]` and `a[mid..hi]` into `a[lo..hi]` as
/// `v` then `u` (half-open indices), using block swaps only.
fn sym_rotate(a: &mut [usize], lo: usize, mid: usize, hi: usize) {
    let mut i = mid - lo;
    let mut j = hi - mid;
    while i != j {
        if i > j {
            sym_swap_range(a, mid - i, mid, j);
            i -= j;
        } else {
            sym_swap_range(a, mid - i, mid + j - i, i);
            j -= i;
        }
    }
    sym_swap_range(a, mid - i, mid, i);
}

/// Kim–Kutzner SymMerge of adjacent sorted runs `a[left..mid]` and `a[mid..right]`.
/// Assumes `left < mid < right` (half-open).
fn sym_merge(a: &mut [usize], left: usize, mid: usize, right: usize) {
    if mid - left == 1 {
        let mut i = mid;
        let mut j = right;
        while i < j {
            let h = (i + j) / 2;
            if a[h] < a[left] {
                i = h + 1;
            } else {
                j = h;
            }
        }
        for k in left..i.saturating_sub(1) {
            a.swap(k, k + 1);
        }
        return;
    }

    if right - mid == 1 {
        let mut i = left;
        let mut j = mid;
        while i < j {
            let h = (i + j) / 2;
            if a[mid] >= a[h] {
                i = h + 1;
            } else {
                j = h;
            }
        }
        let mut k = mid;
        while k > i {
            a.swap(k, k - 1);
            k -= 1;
        }
        return;
    }

    let center = (left + right) / 2;
    let n = center + mid;
    let (mut start, mut r) = if mid > center {
        (n - right, center)
    } else {
        (left, mid)
    };
    let p = n - 1;

    while start < r {
        let c = (start + r) / 2;
        if a[p - c] >= a[c] {
            start = c + 1;
        } else {
            r = c;
        }
    }

    let end = n - start;
    if start < mid && mid < end {
        sym_rotate(a, start, mid, end);
    }
    if left < start && start < center {
        sym_merge(a, left, start, center);
    }
    if center < end && end < right {
        sym_merge(a, center, end, right);
    }
}

fn sym_merge_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }

    const BLOCK: usize = 20;
    let mut start = 0;
    while start < n {
        let end = (start + BLOCK).min(n);
        insertion_sort(&mut a[start..end]);
        start = end;
    }

    let mut width = BLOCK;
    while width < n {
        let mut lo = 0;
        while lo + width < n {
            let mid = lo + width;
            let hi = (lo + 2 * width).min(n);
            sym_merge(a, lo, mid, hi);
            lo = hi;
        }
        width *= 2;
    }
}
