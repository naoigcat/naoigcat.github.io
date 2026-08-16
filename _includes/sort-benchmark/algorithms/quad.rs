/// Sort four elements with a small sorting network (equals keep order via `>`).
fn quad_swap4(a: &mut [usize], i0: usize, i1: usize, i2: usize, i3: usize) {
    if a[i0] > a[i1] {
        a.swap(i0, i1);
    }
    if a[i2] > a[i3] {
        a.swap(i2, i3);
    }
    if a[i0] > a[i2] {
        a.swap(i0, i2);
    }
    if a[i1] > a[i3] {
        a.swap(i1, i3);
    }
    if a[i1] > a[i2] {
        a.swap(i1, i2);
    }
}

fn quad_is_sorted(a: &[usize]) -> bool {
    a.windows(2).all(|w| w[0] <= w[1])
}

fn quad_is_reverse_sorted(a: &[usize]) -> bool {
    a.windows(2).all(|w| w[0] >= w[1])
}

fn quad_reverse(a: &mut [usize]) {
    let mut lo = 0;
    let mut hi = a.len();
    while lo + 1 < hi {
        hi -= 1;
        a.swap(lo, hi);
        lo += 1;
    }
}

/// Stable two-way merge from `src[lo..mid)` and `src[mid..hi)` into `dst[lo..hi)`.
fn quad_merge_two(src: &[usize], dst: &mut [usize], lo: usize, mid: usize, hi: usize) {
    let mut i = lo;
    let mut j = mid;
    let mut k = lo;
    while i < mid && j < hi {
        if src[i] <= src[j] {
            dst[k] = src[i];
            i += 1;
        } else {
            dst[k] = src[j];
            j += 1;
        }
        k += 1;
    }
    while i < mid {
        dst[k] = src[i];
        i += 1;
        k += 1;
    }
    while j < hi {
        dst[k] = src[j];
        j += 1;
        k += 1;
    }
}

/// True when four consecutive sorted blocks of length `block` are already ordered
/// across boundaries (skipping the merge is safe).
fn quad_blocks_ordered(a: &[usize], start: usize, block: usize) -> bool {
    a[start + block - 1] <= a[start + block]
        && a[start + block * 2 - 1] <= a[start + block * 2]
        && a[start + block * 3 - 1] <= a[start + block * 3]
}

/// Ping-pong quad merge: two pairwise merges into swap, then one merge back into `a`.
fn quad_merge_four(a: &mut [usize], swap: &mut [usize], start: usize, block: usize) {
    let mid1 = start + block;
    let mid2 = start + block * 2;
    let mid3 = start + block * 3;
    let end = start + block * 4;
    if quad_blocks_ordered(a, start, block) {
        return;
    }
    quad_merge_two(a, swap, start, mid1, mid2);
    quad_merge_two(a, swap, mid2, mid3, end);
    quad_merge_two(swap, a, start, mid2, end);
}

/// Binary bottom-up merge for a partial span that is not a full group of four blocks.
fn quad_merge_remainder(a: &mut [usize], swap: &mut [usize], start: usize, n: usize, block: usize) {
    let mut width = block;
    while start + width < n {
        let mut lo = start;
        while lo + width < n {
            let mid = lo + width;
            let hi = (lo + width * 2).min(n);
            if a[mid - 1] > a[mid] {
                quad_merge_two(a, swap, lo, mid, hi);
                a[lo..hi].copy_from_slice(&swap[lo..hi]);
            }
            lo = hi;
        }
        width *= 2;
    }
}

fn quad_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    if quad_is_sorted(a) {
        return;
    }
    if quad_is_reverse_sorted(a) {
        quad_reverse(a);
        return;
    }

    // Analyzer / quad-swap: leave sorted blocks of 4 (educational stand-in for 8).
    let mut i = 0;
    while i + 4 <= n {
        quad_swap4(a, i, i + 1, i + 2, i + 3);
        i += 4;
    }
    if i < n {
        for j in (i + 1)..n {
            let key = a[j];
            let mut k = j;
            while k > i && a[k - 1] > key {
                a[k] = a[k - 1];
                k -= 1;
            }
            a[k] = key;
        }
    }

    let mut swap = vec![0usize; n];
    let mut block = 4usize;
    while block < n {
        let stride = block * 4;
        let mut start = 0usize;
        while start < n {
            let rem = n - start;
            if rem <= block {
                break;
            }
            if rem >= stride {
                quad_merge_four(a, &mut swap, start, block);
                start += stride;
            } else {
                quad_merge_remainder(a, &mut swap, start, n, block);
                break;
            }
        }
        block *= 4;
    }
}
