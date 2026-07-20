fn stooge_sort_range(a: &mut [usize], lo: usize, hi: usize) {
    if a[lo] > a[hi] {
        a.swap(lo, hi);
    }
    if hi - lo + 1 <= 2 {
        return;
    }
    let t = (hi - lo + 1) / 3;
    stooge_sort_range(a, lo, hi - t);
    stooge_sort_range(a, lo + t, hi);
    stooge_sort_range(a, lo, hi - t);
}

fn stooge_sort(a: &mut [usize]) {
    if a.len() <= 1 {
        return;
    }
    stooge_sort_range(a, 0, a.len() - 1);
}
