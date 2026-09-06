fn multi_key_digit(value: usize, byte: usize) -> usize {
    let width = std::mem::size_of::<usize>();
    if byte >= width {
        return 0;
    }
    let shift = (width - 1 - byte) * 8;
    (value >> shift) & 0xFF
}

fn multi_key_quick_sort_range(a: &mut [usize], lo: usize, hi: usize, byte: usize) {
    const THRESHOLD: usize = 16;
    const WIDTH: usize = std::mem::size_of::<usize>();

    if hi <= lo {
        return;
    }
    if hi - lo < THRESHOLD {
        insertion_sort(&mut a[lo..=hi]);
        return;
    }
    if byte >= WIDTH {
        return;
    }

    let pivot = multi_key_digit(a[lo], byte);
    let mut lt = lo;
    let mut i = lo + 1;
    let mut gt = hi;

    while i <= gt {
        let d = multi_key_digit(a[i], byte);
        if d < pivot {
            a.swap(lt, i);
            lt += 1;
            i += 1;
        } else if d > pivot {
            a.swap(i, gt);
            gt -= 1;
        } else {
            i += 1;
        }
    }

    if lt > lo {
        multi_key_quick_sort_range(a, lo, lt - 1, byte);
    }
    if gt >= lt {
        multi_key_quick_sort_range(a, lt, gt, byte + 1);
    }
    if gt < hi {
        multi_key_quick_sort_range(a, gt + 1, hi, byte);
    }
}

fn multi_key_quick_sort(a: &mut [usize]) {
    if let Some(hi) = a.len().checked_sub(1) {
        multi_key_quick_sort_range(a, 0, hi, 0);
    }
}
