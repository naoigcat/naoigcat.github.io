fn quick_hoare_partition(a: &mut [usize], lo: usize, hi: usize) -> usize {
    let pivot = a[lo + (hi - lo) / 2];
    let mut i = lo as isize - 1;
    let mut j = hi as isize + 1;
    loop {
        loop {
            i += 1;
            if a[i as usize] >= pivot {
                break;
            }
        }
        loop {
            j -= 1;
            if a[j as usize] <= pivot {
                break;
            }
        }
        if i >= j {
            return j as usize;
        }
        a.swap(i as usize, j as usize);
    }
}

fn quick_hoare_sort_range(a: &mut [usize], lo: usize, hi: usize) {
    if hi <= lo {
        return;
    }
    if hi - lo < 16 {
        insertion_sort(&mut a[lo..=hi]);
        return;
    }
    let p = quick_hoare_partition(a, lo, hi);
    quick_hoare_sort_range(a, lo, p);
    quick_hoare_sort_range(a, p + 1, hi);
}

fn quick_hoare_sort(a: &mut [usize]) {
    if let Some(hi) = a.len().checked_sub(1) {
        quick_hoare_sort_range(a, 0, hi);
    }
}
