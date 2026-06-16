fn comb_sort(a: &mut [usize]) {
    let mut gap = a.len();
    let mut swapped = true;
    while gap > 1 || swapped {
        gap = (gap * 10 / 13).max(1);
        swapped = false;
        for i in 0..a.len().saturating_sub(gap) {
            if a[i] > a[i + gap] {
                a.swap(i, i + gap);
                swapped = true;
            }
        }
    }
}
