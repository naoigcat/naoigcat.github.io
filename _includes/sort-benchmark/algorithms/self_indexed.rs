fn self_indexed_sort(a: &mut [usize]) {
    if a.is_empty() {
        return;
    }

    let min = *a.iter().min().unwrap();
    let max = *a.iter().max().unwrap();
    let span = max - min + 1;

    // Phase 1: initialize sorting space
    let mut ss = vec![0usize; span];

    // Phase 2: self-indexed arrangement (key maps to offset in ss)
    for &x in a.iter() {
        ss[x - min] += 1;
    }

    // Phase 3: order-preserved compression back into the original array
    let mut idx = 0;

    for (offset, &cnt) in ss.iter().enumerate() {
        let value = min + offset;
        for _ in 0..cnt {
            a[idx] = value;
            idx += 1;
        }
    }
}
