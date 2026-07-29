fn compare_exchange(a: &mut [usize], i: usize, j: usize, dir_up: bool) {
    let swap = if dir_up {
        a[i] > a[j]
    } else {
        a[i] < a[j]
    };
    if swap {
        a.swap(i, j);
    }
}

fn bitonic_merge(a: &mut [usize], lo: usize, cnt: usize, dir_up: bool) {
    if cnt <= 1 {
        return;
    }
    let k = cnt / 2;
    for i in lo..lo + k {
        compare_exchange(a, i, i + k, dir_up);
    }
    bitonic_merge(a, lo, k, dir_up);
    bitonic_merge(a, lo + k, k, dir_up);
}

fn bitonic_sort_range(a: &mut [usize], lo: usize, cnt: usize, dir_up: bool) {
    if cnt <= 1 {
        return;
    }
    let k = cnt / 2;
    bitonic_sort_range(a, lo, k, true);
    bitonic_sort_range(a, lo + k, k, false);
    bitonic_merge(a, lo, cnt, dir_up);
}

fn bitonic_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    if n.is_power_of_two() {
        bitonic_sort_range(a, 0, n, true);
        return;
    }
    // Classic bitonic sort assumes a power-of-two length; pad for other sizes.
    let k = n.next_power_of_two();
    let mut buf = vec![usize::MAX; k];
    buf[..n].copy_from_slice(a);
    bitonic_sort_range(&mut buf, 0, k, true);
    a.copy_from_slice(&buf[..n]);
}
