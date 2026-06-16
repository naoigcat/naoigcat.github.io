fn kota_insertion_sort(a: &mut [usize], lo: usize, hi: usize) {
    for i in lo + 1..hi {
        let key = a[i];
        let mut j = i;
        while j > lo && a[j - 1] > key {
            a[j] = a[j - 1];
            j -= 1;
        }
        a[j] = key;
    }
}

fn kota_block_swap(a: &mut [usize], start: usize, block_len: usize, i: usize, j: usize) {
    let bi = start + i * block_len;
    let bj = start + j * block_len;
    for k in 0..block_len {
        a.swap(bi + k, bj + k);
    }
}

fn kota_block_select(a: &mut [usize], start: usize, block_count: usize, block_len: usize) {
    for i in 0..block_count {
        let mut min = i;
        for j in i + 1..block_count {
            if a[start + j * block_len] < a[start + min * block_len] {
                min = j;
            }
        }
        if min != i {
            kota_block_swap(a, start, block_len, i, min);
        }
    }
}

fn kota_merge_with_buffer(a: &mut [usize], lo: usize, mid: usize, hi: usize, buf: &mut Vec<usize>) {
    let left_len = mid - lo;
    buf.resize(left_len, 0);
    buf[..left_len].copy_from_slice(&a[lo..mid]);
    let mut i = 0usize;
    let mut j = mid;
    let mut k = lo;
    while i < left_len && j < hi {
        if buf[i] <= a[j] {
            a[k] = buf[i];
            i += 1;
        } else {
            a[k] = a[j];
            j += 1;
        }
        k += 1;
    }
    while i < left_len {
        a[k] = buf[i];
        i += 1;
        k += 1;
    }
}

fn kota_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }

    let run_size = 16usize;
    let block_len = (n as f64).sqrt() as usize;
    let block_len = block_len.max(1);

    if n < run_size {
        kota_insertion_sort(a, 0, n);
        return;
    }

    for start in (0..n).step_by(run_size) {
        let end = (start + run_size).min(n);
        kota_insertion_sort(a, start, end);
    }

    let mut merge_buf = Vec::new();
    let mut width = run_size;
    while width < n {
        for lo in (0..n).step_by(width * 2) {
            let mid = (lo + width).min(n);
            let hi = (lo + width * 2).min(n);
            if mid >= hi {
                continue;
            }
            kota_merge_with_buffer(a, lo, mid, hi, &mut merge_buf);
            let span = hi - lo;
            if span >= block_len * 2 {
                let block_count = span / block_len;
                kota_block_select(a, lo, block_count, block_len);
            }
        }
        width *= 2;
    }
}
