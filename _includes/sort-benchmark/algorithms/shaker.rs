fn shaker_sort(a: &mut [usize]) {
    if a.len() <= 1 {
        return;
    }
    let mut left = 0;
    let mut right = a.len() - 1;
    while left < right {
        let mut swapped = false;
        for i in left..right {
            if a[i] > a[i + 1] {
                a.swap(i, i + 1);
                swapped = true;
            }
        }
        if !swapped {
            break;
        }
        right -= 1;
        swapped = false;
        for i in (left + 1..=right).rev() {
            if a[i - 1] > a[i] {
                a.swap(i - 1, i);
                swapped = true;
            }
        }
        if !swapped {
            break;
        }
        left += 1;
    }
}
