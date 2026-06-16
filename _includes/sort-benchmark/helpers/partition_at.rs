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
