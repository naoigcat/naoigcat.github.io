fn quick_random_pivot_next(state: &mut u64) -> u64 {
    let mut s = *state;
    s ^= s << 13;
    s ^= s >> 7;
    s ^= s << 17;
    *state = s;
    s
}

fn quick_random_pivot_sort_range(a: &mut [usize], lo: usize, hi: usize, rng: &mut u64) {
    if hi <= lo {
        return;
    }
    if hi - lo < 16 {
        insertion_sort(&mut a[lo..=hi]);
        return;
    }
    let pivot_idx = lo + (quick_random_pivot_next(rng) as usize % (hi - lo + 1));
    let p = partition_at(a, lo, hi, pivot_idx);
    if p > 0 {
        quick_random_pivot_sort_range(a, lo, p - 1, rng);
    }
    quick_random_pivot_sort_range(a, p + 1, hi, rng);
}

fn quick_random_pivot_sort(a: &mut [usize]) {
    if let Some(hi) = a.len().checked_sub(1) {
        let mut rng = 0x9e3779b97f4a7c15u64 ^ (a.len() as u64);
        quick_random_pivot_sort_range(a, 0, hi, &mut rng);
    }
}
