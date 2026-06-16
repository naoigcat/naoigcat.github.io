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
