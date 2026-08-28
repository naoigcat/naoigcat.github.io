fn get_flag(r: &[u8], x: usize) -> usize {
    ((r[x >> 3] >> (x & 7)) & 1) as usize
}

fn toggle_flag(r: &mut [u8], x: usize) {
    r[x >> 3] ^= 1 << (x & 7);
}

/// Join two equal-height weak heaps rooted at `i` (distinguished ancestor) and `j`.
/// Max-heap form: if `a[j]` is larger, promote it and flip the reverse bit at `j`.
fn join(a: &mut [usize], r: &mut [u8], i: usize, j: usize) {
    if a[i] < a[j] {
        toggle_flag(r, j);
        a.swap(i, j);
    }
}

fn distinguished_ancestor(r: &[u8], mut j: usize) -> usize {
    while (j & 1) == get_flag(r, j >> 1) {
        j >>= 1;
    }
    j >> 1
}

fn weak_heap_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }

    let mut r = vec![0u8; (n + 7) / 8];

    // Bottom-up construct: n - 1 joins with each node's distinguished ancestor.
    for i in (1..n).rev() {
        let g = distinguished_ancestor(&r, i);
        join(a, &mut r, g, i);
    }

    // Extract maxima like heapsort; sift-down uses left-spine + upward joins.
    for end in (2..n).rev() {
        a.swap(0, end);
        let mut x = 1usize;
        while {
            let y = 2 * x + get_flag(&r, x);
            y < end
        } {
            x = 2 * x + get_flag(&r, x);
        }
        while x > 0 {
            join(a, &mut r, 0, x);
            x >>= 1;
        }
    }
    a.swap(0, 1);
}
