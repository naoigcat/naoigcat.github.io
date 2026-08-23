fn postman_sort_bytes(a: &mut [usize], byte: usize) {
    const W: usize = 256;
    const THRESHOLD: usize = 16;

    if a.len() <= THRESHOLD {
        insertion_sort(a);
        return;
    }
    if byte >= std::mem::size_of::<usize>() {
        return;
    }

    let shift = (std::mem::size_of::<usize>() - 1 - byte) * 8;
    let mut buckets: [Vec<usize>; W] = std::array::from_fn(|_| Vec::new());

    for &value in a.iter() {
        let digit = ((value >> shift) & 0xFF) as usize;
        buckets[digit].push(value);
    }

    let mut offset = 0usize;
    for bucket in buckets.iter_mut() {
        if bucket.len() > 1 {
            postman_sort_bytes(bucket, byte + 1);
        }
        let len = bucket.len();
        if len > 0 {
            a[offset..offset + len].copy_from_slice(bucket);
            offset += len;
        }
    }
}

fn postman_sort(a: &mut [usize]) {
    if !a.is_empty() {
        postman_sort_bytes(a, 0);
    }
}
