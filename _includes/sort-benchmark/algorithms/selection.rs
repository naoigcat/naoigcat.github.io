fn selection_sort(a: &mut [usize]) {
    for i in 0..a.len() {
        let mut min = i;
        for j in i + 1..a.len() {
            if a[j] < a[min] {
                min = j;
            }
        }
        a.swap(i, min);
    }
}
