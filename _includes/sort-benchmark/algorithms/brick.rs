fn brick_sort(a: &mut [usize]) {
    let mut sorted = false;
    while !sorted {
        sorted = true;
        for i in (1..a.len()).step_by(2) {
            if a[i - 1] > a[i] {
                a.swap(i - 1, i);
                sorted = false;
            }
        }
        for i in (2..a.len()).step_by(2) {
            if a[i - 1] > a[i] {
                a.swap(i - 1, i);
                sorted = false;
            }
        }
    }
}
