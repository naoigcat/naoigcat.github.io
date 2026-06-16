fn sample_sort(a: &mut [usize]) {
    if a.len() <= 32 {
        insertion_sort(a);
        return;
    }
    let sample_count = (a.len() as f64).sqrt() as usize;
    let step = (a.len() / sample_count.max(1)).max(1);
    let mut splitters: Vec<usize> = (step - 1..a.len())
        .step_by(step)
        .take(sample_count)
        .map(|i| a[i])
        .collect();
    quick_sort(&mut splitters);
    let mut buckets = vec![Vec::new(); splitters.len() + 1];
    for &value in a.iter() {
        let bucket = splitters.partition_point(|&splitter| value > splitter);
        buckets[bucket].push(value);
    }
    let mut pos = 0;
    for bucket in buckets.iter_mut() {
        sample_sort(bucket);
        for &value in bucket.iter() {
            a[pos] = value;
            pos += 1;
        }
    }
}
