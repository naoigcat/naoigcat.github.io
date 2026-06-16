fn exchange_sort(a: &mut [usize]) {
    for i in 0..a.len() {
        for j in i + 1..a.len() {
            if a[j] < a[i] {
                a.swap(i, j);
            }
        }
    }
}
