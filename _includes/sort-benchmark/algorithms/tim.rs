fn tim_sort(a: &mut [usize]) {
    const MIN_RUN: usize = 32;
    let n = a.len();
    let mut runs = Vec::new();
    let mut i = 0;
    while i < n {
        let start = i;
        i += 1;
        if i < n && a[i - 1] > a[i] {
            while i < n && a[i - 1] > a[i] {
                i += 1;
            }
            a[start..i].reverse();
        } else {
            while i < n && a[i - 1] <= a[i] {
                i += 1;
            }
        }
        let end = (start + MIN_RUN).min(n).max(i);
        insertion_sort(&mut a[start..end]);
        runs.push((start, end));
        i = end;
    }
    while runs.len() > 1 {
        let mut next = Vec::new();
        for pair in runs.chunks(2) {
            if pair.len() == 1 {
                next.push(pair[0]);
                continue;
            }
            let (lo, mid) = pair[0];
            let (_, hi) = pair[1];
            let mut merged = Vec::with_capacity(hi - lo);
            let (mut l, mut r) = (lo, mid);
            while l < mid && r < hi {
                if a[l] <= a[r] {
                    merged.push(a[l]);
                    l += 1;
                } else {
                    merged.push(a[r]);
                    r += 1;
                }
            }
            merged.extend_from_slice(&a[l..mid]);
            merged.extend_from_slice(&a[r..hi]);
            a[lo..hi].copy_from_slice(&merged);
            next.push((lo, hi));
        }
        runs = next;
    }
}
