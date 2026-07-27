fn natural_merge_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    loop {
        let mut runs = Vec::new();
        let mut i = 0;
        while i < n {
            let start = i;
            i += 1;
            while i < n && a[i - 1] <= a[i] {
                i += 1;
            }
            runs.push((start, i));
        }
        if runs.len() <= 1 {
            return;
        }
        let mut k = 0;
        while k + 1 < runs.len() {
            let (lo, mid) = runs[k];
            let (_, hi) = runs[k + 1];
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
            k += 2;
        }
    }
}
