fn binary_quick_sort_bit(a: &mut [usize], bit: i32) {
    const THRESHOLD: usize = 16;

    if a.len() <= 1 || bit < 0 {
        return;
    }
    if a.len() <= THRESHOLD {
        insertion_sort(a);
        return;
    }

    let mut i = 0usize;
    let mut j = a.len();
    while i < j {
        while i < j && ((a[i] >> bit) & 1) == 0 {
            i += 1;
        }
        while i < j && ((a[j - 1] >> bit) & 1) == 1 {
            j -= 1;
        }
        if i < j {
            a.swap(i, j - 1);
            i += 1;
            j -= 1;
        }
    }

    let mid = i;
    binary_quick_sort_bit(&mut a[..mid], bit - 1);
    binary_quick_sort_bit(&mut a[mid..], bit - 1);
}

fn binary_quick_sort(a: &mut [usize]) {
    if a.len() <= 1 {
        return;
    }
    let max = *a.iter().max().unwrap();
    let bit = if max == 0 {
        0
    } else {
        (usize::BITS - 1 - max.leading_zeros()) as i32
    };
    binary_quick_sort_bit(a, bit);
}
