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
    let n = a.len();
    if n <= 1 {
        return;
    }
    if n.is_power_of_two() {
        odd_even_merge_sort_range(a, 0, n);
        return;
    }
    // Classic odd-even mergesort assumes a power-of-two length; pad for other sizes.
    let k = n.next_power_of_two();
    let mut buf = vec![usize::MAX; k];
    buf[..n].copy_from_slice(a);
    odd_even_merge_sort_range(&mut buf, 0, k);
    a.copy_from_slice(&buf[..n]);
}
