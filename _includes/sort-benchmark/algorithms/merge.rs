fn merge_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    let mid = n / 2;
    merge_sort(&mut a[..mid]);
    merge_sort(&mut a[mid..]);
    let mut merged = Vec::with_capacity(n);
    let (mut l, mut r) = (0, mid);
    while l < mid && r < n {
        if a[l] <= a[r] {
            merged.push(a[l]);
            l += 1;
        } else {
            merged.push(a[r]);
            r += 1;
        }
    }
    merged.extend_from_slice(&a[l..mid]);
    merged.extend_from_slice(&a[r..]);
    a.copy_from_slice(&merged);
}
