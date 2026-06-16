fn gnome_sort(a: &mut [usize]) {
    let mut i = 1;
    while i < a.len() {
        if i == 0 || a[i - 1] <= a[i] {
            i += 1;
        } else {
            a.swap(i - 1, i);
            i -= 1;
        }
    }
}
