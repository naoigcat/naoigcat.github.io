fn wmerge(a: &mut [usize], i: usize, m: usize, j: usize, n: usize, mut w: usize) {
    let mut i = i;
    let mut j = j;
    while i < m && j < n {
        if a[i] <= a[j] {
            a.swap(w, i);
            w += 1;
            i += 1;
        } else {
            a.swap(w, j);
            w += 1;
            j += 1;
        }
    }
    while i < m {
        a.swap(w, i);
        w += 1;
        i += 1;
    }
    while j < n {
        a.swap(w, j);
        w += 1;
        j += 1;
    }
}

fn wsort(a: &mut [usize], l: usize, u: usize, w: usize) {
    if u - l > 1 {
        let m = l + (u - l) / 2;
        imsort_range(a, l, m);
        imsort_range(a, m, u);
        wmerge(a, l, m, m, u, w);
    } else {
        let mut l = l;
        let mut w = w;
        while l < u {
            a.swap(l, w);
            l += 1;
            w += 1;
        }
    }
}

fn imsort_range(a: &mut [usize], l: usize, u: usize) {
    if u - l <= 1 {
        return;
    }
    let m = l + (u - l) / 2;
    let mut w = l + u - m;
    wsort(a, l, m, w);
    while w - l > 2 {
        let n = w;
        w = l + (n - l + 1) / 2;
        wsort(a, w, n, l);
        wmerge(a, l, l + n - w, n, u, w);
    }
    let mut n = w;
    while n > l {
        let mut m_idx = n;
        while m_idx < u && a[m_idx] < a[m_idx - 1] {
            a.swap(m_idx, m_idx - 1);
            m_idx += 1;
        }
        n -= 1;
    }
}

fn cascade_merge_sort(a: &mut [usize]) {
    if a.len() <= 1 {
        return;
    }
    imsort_range(a, 0, a.len());
}
