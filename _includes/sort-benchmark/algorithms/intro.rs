fn intro_sort_range(a: &mut [usize], lo: usize, hi: usize, depth: usize) {
    if hi <= lo {
        return;
    }
    if hi - lo < 16 {
        insertion_sort(&mut a[lo..=hi]);
        return;
    }
    if depth == 0 {
        heap_sort(&mut a[lo..=hi]);
        return;
    }
    let p = partition(a, lo, hi);
    if p > 0 {
        intro_sort_range(a, lo, p - 1, depth - 1);
    }
    intro_sort_range(a, p + 1, hi, depth - 1);
}

fn intro_sort(a: &mut [usize]) {
    if let Some(hi) = a.len().checked_sub(1) {
        let depth = usize::BITS as usize - a.len().leading_zeros() as usize;
        intro_sort_range(a, 0, hi, depth * 2);
    }
}
