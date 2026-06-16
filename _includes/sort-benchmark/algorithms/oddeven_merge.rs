fn odd_even_merge(a: &mut [usize], lo: usize, n: usize, r: usize) {
    let m = r * 2;
    if m < n {
        odd_even_merge(a, lo, n, m);
        odd_even_merge(a, lo + r, n, m);
        let mut i = lo + r;
        while i + r < lo + n {
            if a[i] > a[i + r] {
                a.swap(i, i + r);
            }
            i += m;
        }
    } else if lo + r < a.len() {
        if a[lo] > a[lo + r] {
            a.swap(lo, lo + r);
        }
    }
}

fn odd_even_merge_sort_range(a: &mut [usize], lo: usize, n: usize) {
    if n <= 1 {
        return;
    }
    let half = n / 2;
    odd_even_merge_sort_range(a, lo, half);
    odd_even_merge_sort_range(a, lo + half, half);
    odd_even_merge(a, lo, n, 1);
}

fn odd_even_merge_sort(a: &mut [usize]) {
    if a.is_empty() {
        return;
    }
    odd_even_merge_sort_range(a, 0, a.len());
}
