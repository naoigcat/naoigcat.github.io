fn bucket_sort(a: &mut [usize]) {
    if a.is_empty() {
        return;
    }

    let n = a.len();
    let min = *a.iter().min().unwrap();
    let max = *a.iter().max().unwrap();
    let bucket_count = n;
    let mut buckets: Vec<Vec<usize>> = vec![Vec::new(); bucket_count];

    for &x in a.iter() {
        let idx = if max == min {
            0
        } else {
            ((x - min) as f64 / (max - min) as f64 * (bucket_count - 1) as f64).floor() as usize
        };
        buckets[idx].push(x);
    }

    for bucket in buckets.iter_mut() {
        insertion_sort(bucket);
    }

    let mut idx = 0;
    for bucket in buckets.iter() {
        for &x in bucket.iter() {
            a[idx] = x;
            idx += 1;
        }
    }
}
