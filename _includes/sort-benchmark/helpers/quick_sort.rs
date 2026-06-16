fn quick_sort_range(a: &mut [usize], lo: usize, hi: usize) {
    if hi <= lo {
        return;
    }
    if hi - lo < 16 {
        insertion_sort(&mut a[lo..=hi]);
        return;
    }
    let p = partition(a, lo, hi);
    if p > 0 {
        quick_sort_range(a, lo, p - 1);
    }
    quick_sort_range(a, p + 1, hi);
}

fn quick_sort(a: &mut [usize]) {
    if let Some(hi) = a.len().checked_sub(1) {
        quick_sort_range(a, 0, hi);
    }
}
