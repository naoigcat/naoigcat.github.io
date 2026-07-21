fn slow_sort_range(a: &mut [usize], lo: usize, hi: usize) {
    if lo >= hi {
        return;
    }
    let m = (lo + hi) / 2;
    slow_sort_range(a, lo, m);
    slow_sort_range(a, m + 1, hi);
    if a[m] > a[hi] {
        a.swap(m, hi);
    }
    slow_sort_range(a, lo, hi - 1);
}

fn slow_sort(a: &mut [usize]) {
    if a.len() <= 1 {
        return;
    }
    slow_sort_range(a, 0, a.len() - 1);
}
