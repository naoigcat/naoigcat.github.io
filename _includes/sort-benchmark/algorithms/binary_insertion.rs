fn binary_insertion_sort(a: &mut [usize]) {
    for i in 1..a.len() {
        let key = a[i];
        let mut lo = 0;
        let mut hi = i;
        while lo < hi {
            let mid = lo + (hi - lo) / 2;
            if a[mid] > key {
                hi = mid;
            } else {
                lo = mid + 1;
            }
        }
        for j in (lo..i).rev() {
            a[j + 1] = a[j];
        }
        a[lo] = key;
    }
}
