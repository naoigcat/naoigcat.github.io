fn flash_class_index(x: usize, min: usize, max: usize, m: usize) -> usize {
    if max == min {
        0
    } else {
        ((x - min) as f64 / (max - min) as f64 * (m - 1) as f64) as usize
    }
}

fn flash_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }

    let min = *a.iter().min().unwrap();
    let max = *a.iter().max().unwrap();
    if min == max {
        return;
    }

    let m = ((n as f64 * (2.0 * n as f64).log2()).sqrt().ceil() as usize).clamp(2, n);

    let mut count = vec![0usize; m];
    for &x in a.iter() {
        count[flash_class_index(x, min, max, m)] += 1;
    }

    let mut boundary = vec![0usize; m + 1];
    for i in 0..m {
        boundary[i + 1] = boundary[i] + count[i];
    }

    let mut temp = vec![0usize; n];
    let mut cursor = boundary.clone();
    for &x in a.iter() {
        let k = flash_class_index(x, min, max, m);
        temp[cursor[k]] = x;
        cursor[k] += 1;
    }
    a.copy_from_slice(&temp);

    for i in 0..m {
        let start = boundary[i];
        let end = boundary[i + 1];
        if end - start > 1 {
            insertion_sort(&mut a[start..end]);
        }
    }
}
