const BLOCK_SIZE: usize = 128;
const INSERTION_THRESHOLD: usize = 16;

/// Branch-light Hoare-style partition used by BlockQuicksort (Edelkamp & Weiß).
/// Returns the final index of the pivot.
fn quick_block_partition(a: &mut [usize], mut begin: usize, end: usize) -> usize {
    // end is exclusive; pivot starts at midpoint of [begin, end).
    let mid = begin + (end - begin) / 2;
    a.swap(mid, end - 1);
    let pivot = a[end - 1];
    let mut last = end - 2;

    let mut index_l = [0usize; BLOCK_SIZE];
    let mut index_r = [0usize; BLOCK_SIZE];
    let mut num_left = 0usize;
    let mut num_right = 0usize;
    let mut start_left = 0usize;
    let mut start_right = 0usize;

    while begin <= last && last - begin + 1 > 2 * BLOCK_SIZE {
        if num_left == 0 {
            start_left = 0;
            for j in 0..BLOCK_SIZE {
                index_l[num_left] = j;
                // left buffer: elements >= pivot (need to move right)
                num_left += usize::from(!(a[begin + j] < pivot));
            }
        }
        if num_right == 0 {
            start_right = 0;
            for j in 0..BLOCK_SIZE {
                index_r[num_right] = j;
                // right buffer: elements <= pivot (need to move left)
                num_right += usize::from(!(pivot < a[last - j]));
            }
        }

        let num = num_left.min(num_right);
        for j in 0..num {
            let li = begin + index_l[start_left + j];
            let ri = last - index_r[start_right + j];
            a.swap(li, ri);
        }
        num_left -= num;
        num_right -= num;
        start_left += num;
        start_right += num;
        if num_left == 0 {
            begin += BLOCK_SIZE;
        }
        if num_right == 0 {
            last -= BLOCK_SIZE;
        }
    }

    // Final (partial) scan of the remaining ≤ 2B elements.
    let (shift_l, shift_r) = if num_right == 0 && num_left == 0 {
        debug_assert!(begin <= last);
        let len = last - begin + 1;
        let shift_l = len / 2;
        let shift_r = len - shift_l;
        start_left = 0;
        start_right = 0;
        for j in 0..shift_l {
            index_l[num_left] = j;
            num_left += usize::from(!(a[begin + j] < pivot));
            index_r[num_right] = j;
            num_right += usize::from(!(pivot < a[last - j]));
        }
        if shift_l < shift_r {
            index_r[num_right] = shift_r - 1;
            num_right += usize::from(!(pivot < a[last - (shift_r - 1)]));
        }
        (shift_l, shift_r)
    } else if num_right != 0 {
        let shift_l = last - begin + 1 - BLOCK_SIZE;
        start_left = 0;
        for j in 0..shift_l {
            index_l[num_left] = j;
            num_left += usize::from(!(a[begin + j] < pivot));
        }
        (shift_l, BLOCK_SIZE)
    } else {
        let shift_r = last - begin + 1 - BLOCK_SIZE;
        start_right = 0;
        for j in 0..shift_r {
            index_r[num_right] = j;
            num_right += usize::from(!(pivot < a[last - j]));
        }
        (BLOCK_SIZE, shift_r)
    };

    let num = num_left.min(num_right);
    for j in 0..num {
        let li = begin + index_l[start_left + j];
        let ri = last - index_r[start_right + j];
        a.swap(li, ri);
    }
    num_left -= num;
    num_right -= num;
    start_left += num;
    start_right += num;
    if num_left == 0 {
        begin += shift_l;
    }
    if num_right == 0 {
        last = last.wrapping_sub(shift_r);
    }

    // Drain leftovers still recorded in one buffer.
    // `upper` is signed because the reference finish may leave it at -1.
    if num_left != 0 {
        let mut lower_i = (start_left + num_left - 1) as isize;
        let mut upper = last as isize - begin as isize;
        while lower_i >= start_left as isize && index_l[lower_i as usize] as isize == upper {
            upper -= 1;
            lower_i -= 1;
        }
        while lower_i >= start_left as isize {
            a.swap(
                (begin as isize + upper) as usize,
                begin + index_l[lower_i as usize],
            );
            upper -= 1;
            lower_i -= 1;
        }
        let pivot_pos = (begin as isize + upper + 1) as usize;
        a.swap(end - 1, pivot_pos);
        pivot_pos
    } else if num_right != 0 {
        let mut lower_i = (start_right + num_right - 1) as isize;
        let mut upper = last as isize - begin as isize;
        while lower_i >= start_right as isize && index_r[lower_i as usize] as isize == upper {
            upper -= 1;
            lower_i -= 1;
        }
        while lower_i >= start_right as isize {
            a.swap(
                (last as isize - upper) as usize,
                (last as isize - index_r[lower_i as usize] as isize) as usize,
            );
            upper -= 1;
            lower_i -= 1;
        }
        let pivot_pos = (last as isize - upper) as usize;
        a.swap(end - 1, pivot_pos);
        pivot_pos
    } else {
        a.swap(end - 1, begin);
        begin
    }
}

fn quick_block_sort_range(a: &mut [usize], lo: usize, hi: usize) {
    if hi <= lo {
        return;
    }
    if hi - lo < INSERTION_THRESHOLD {
        insertion_sort(&mut a[lo..=hi]);
        return;
    }
    let pivot_pos = quick_block_partition(a, lo, hi + 1);
    if pivot_pos > lo {
        quick_block_sort_range(a, lo, pivot_pos - 1);
    }
    if pivot_pos < hi {
        quick_block_sort_range(a, pivot_pos + 1, hi);
    }
}

fn quick_block_sort(a: &mut [usize]) {
    if let Some(hi) = a.len().checked_sub(1) {
        quick_block_sort_range(a, 0, hi);
    }
}
