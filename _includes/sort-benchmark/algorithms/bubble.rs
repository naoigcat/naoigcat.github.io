fn bubble_sort(a: &mut [usize]) {
    if a.len() <= 1 {
        return;
    }

    let mut last = a.len() - 1;

    while last > 0 {
        let mut new_last = 0;

        for i in 0..last {
            if a[i] > a[i + 1] {
                a.swap(i, i + 1);
                new_last = i;
            }
        }

        last = new_last;
    }
}
