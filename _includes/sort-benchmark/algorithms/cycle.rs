fn cycle_sort(a: &mut [usize]) {
    let n = a.len();
    for cycle_start in 0..n.saturating_sub(1) {
        let mut item = a[cycle_start];
        let mut pos = cycle_start;
        for i in cycle_start + 1..n {
            if a[i] < item {
                pos += 1;
            }
        }
        if pos == cycle_start {
            continue;
        }
        while pos < n && a[pos] == item {
            pos += 1;
        }
        std::mem::swap(&mut a[pos], &mut item);
        while pos != cycle_start {
            pos = cycle_start;
            for i in cycle_start + 1..n {
                if a[i] < item {
                    pos += 1;
                }
            }
            while pos < n && a[pos] == item {
                pos += 1;
            }
            std::mem::swap(&mut a[pos], &mut item);
        }
    }
}
