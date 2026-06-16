fn flip_prefix(a: &mut [usize], end: usize) {
    let mut lo = 0;
    let mut hi = end;
    while lo < hi {
        a.swap(lo, hi);
        lo += 1;
        hi -= 1;
    }
}

fn pancake_sort(a: &mut [usize]) {
    let n = a.len();
    for size in (2..=n).rev() {
        let mut max_idx = 0;
        for i in 1..size {
            if a[i] > a[max_idx] {
                max_idx = i;
            }
        }
        if max_idx != size - 1 {
            if max_idx != 0 {
                flip_prefix(a, max_idx);
            }
            flip_prefix(a, size - 1);
        }
    }
}
