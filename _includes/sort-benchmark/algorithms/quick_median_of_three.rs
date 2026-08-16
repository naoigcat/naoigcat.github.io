fn quick_median_of_three_idx(a: &[usize], lo: usize, hi: usize) -> usize {
    let mid = lo + (hi - lo) / 2;
    let (x, y, z) = (a[lo], a[mid], a[hi]);
    if (x <= y && y <= z) || (z <= y && y <= x) {
        mid
    } else if (y <= x && x <= z) || (z <= x && x <= y) {
        lo
    } else {
        hi
    }
}

fn quick_median_of_three_sort_range(a: &mut [usize], lo: usize, hi: usize) {
    if hi <= lo {
        return;
    }
    if hi - lo < 16 {
        insertion_sort(&mut a[lo..=hi]);
        return;
    }
    let pivot_idx = quick_median_of_three_idx(a, lo, hi);
    let p = partition_at(a, lo, hi, pivot_idx);
    if p > 0 {
        quick_median_of_three_sort_range(a, lo, p - 1);
    }
    quick_median_of_three_sort_range(a, p + 1, hi);
}

fn quick_median_of_three_sort(a: &mut [usize]) {
    if let Some(hi) = a.len().checked_sub(1) {
        quick_median_of_three_sort_range(a, 0, hi);
    }
}
