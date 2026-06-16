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
