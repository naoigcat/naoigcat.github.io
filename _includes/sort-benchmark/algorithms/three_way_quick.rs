fn three_way_quick_sort_range(a: &mut [usize], lo: usize, hi: usize) {
    if hi <= lo {
        return;
    }
    if hi - lo < 16 {
        insertion_sort(&mut a[lo..=hi]);
        return;
    }

    let pivot = a[lo];
    let mut lt = lo;
    let mut i = lo + 1;
    let mut gt = hi;

    while i <= gt {
        if a[i] < pivot {
            a.swap(lt, i);
            lt += 1;
            i += 1;
        } else if a[i] > pivot {
            a.swap(i, gt);
            gt -= 1;
        } else {
            i += 1;
        }
    }

    if lt > lo {
        three_way_quick_sort_range(a, lo, lt - 1);
    }
    if gt < hi {
        three_way_quick_sort_range(a, gt + 1, hi);
    }
}

fn three_way_quick_sort(a: &mut [usize]) {
    if let Some(hi) = a.len().checked_sub(1) {
        three_way_quick_sort_range(a, 0, hi);
    }
}
