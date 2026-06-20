fn counting_sort(a: &mut [usize]) {
    if a.is_empty() {
        return;
    }

    let min = *a.iter().min().unwrap();
    let max = *a.iter().max().unwrap();
    let span = max - min + 1;
    let mut count = vec![0usize; span];

    for &x in a.iter() {
        count[x - min] += 1;
    }

    let mut idx = 0;

    for (offset, &cnt) in count.iter().enumerate() {
        let value = min + offset;
        for _ in 0..cnt {
            a[idx] = value;
            idx += 1;
        }
    }
}
