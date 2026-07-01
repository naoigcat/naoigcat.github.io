fn american_flag_sort_bytes(a: &mut [usize], byte: usize) {
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

    let mut count = [0usize; W];
    for &value in a.iter() {
        count[((value >> shift) & 0xFF) as usize] += 1;
    }

    let mut begin = [0usize; W];
    let mut sum = 0usize;
    for i in 0..W {
        begin[i] = sum;
        sum += count[i];
    }

    let initial = begin;
    let mut end = [0usize; W];
    for i in 0..W {
        end[i] = begin[i] + count[i];
    }

    for bucket in 0..W {
        if count[bucket] == 0 {
            continue;
        }

        while begin[bucket] < end[bucket] {
            let digit = ((a[begin[bucket]] >> shift) & 0xFF) as usize;
            if digit != bucket {
                end[digit] -= 1;
                a.swap(begin[bucket], end[digit]);
            } else {
                begin[bucket] += 1;
            }
        }

        let start = initial[bucket];
        if count[bucket] > 1 {
            american_flag_sort_bytes(&mut a[start..start + count[bucket]], byte + 1);
        }
    }
}

fn american_flag_sort(a: &mut [usize]) {
    if !a.is_empty() {
        american_flag_sort_bytes(a, 0);
    }
}
