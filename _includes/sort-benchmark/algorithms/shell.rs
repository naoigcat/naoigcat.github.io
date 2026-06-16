fn shell_sort(a: &mut [usize]) {
    let mut gap = a.len() / 2;
    while gap > 0 {
        for i in gap..a.len() {
            let x = a[i];
            let mut j = i;
            while j >= gap && a[j - gap] > x {
                a[j] = a[j - gap];
                j -= gap;
            }
            a[j] = x;
        }
        gap /= 2;
    }
}
