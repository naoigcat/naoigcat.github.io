fn dual_pivot_quick_sort_range(a: &mut [usize], lo: usize, hi: usize) {
    if hi <= lo {
        return;
    }
    if hi - lo < 16 {
        insertion_sort(&mut a[lo..=hi]);
        return;
    }

    if a[lo] > a[hi] {
        a.swap(lo, hi);
    }
    let pivot1 = a[lo];
    let pivot2 = a[hi];

    let mut less = lo + 1;
    let mut great = hi - 1;
    let mut k = less;

    while k <= great {
        if a[k] < pivot1 {
            a.swap(k, less);
            less += 1;
            k += 1;
        } else if a[k] > pivot2 {
            while k < great && a[great] > pivot2 {
                great -= 1;
            }
            a.swap(k, great);
            great -= 1;
            if a[k] < pivot1 {
                a.swap(k, less);
                less += 1;
            }
            k += 1;
        } else {
            k += 1;
        }
    }

    a.swap(lo, less - 1);
    a.swap(hi, great + 1);

    if lo + 1 < less {
        dual_pivot_quick_sort_range(a, lo, less - 2);
    }
    if less < great {
        dual_pivot_quick_sort_range(a, less, great);
    }
    if great + 1 < hi {
        dual_pivot_quick_sort_range(a, great + 2, hi);
    }
}

fn dual_pivot_quick_sort(a: &mut [usize]) {
    if let Some(hi) = a.len().checked_sub(1) {
        dual_pivot_quick_sort_range(a, 0, hi);
    }
}
