const MEAN_BIN_SIZE: usize = 4;
const MIN_BIN_COUNT: usize = 16;

fn rough_log2_size(n: usize) -> u32 {
    if n == 0 {
        0
    } else {
        usize::BITS - 1 - n.leading_zeros()
    }
}

fn get_max_count(log_range: u32, count: usize) -> usize {
    const MAX_SPLITS: u32 = 11;
    const LOG_CONST: u32 = 2;
    const LOG_MEAN_BIN_SIZE: u32 = 2;
    const LOG_MIN_SPLIT_COUNT: u32 = 4;
    let data_size = usize::BITS;

    let log_size = rough_log2_size(count);
    let denom = log_size.min(MAX_SPLITS).max(1);
    let mut relative_width = (LOG_CONST * log_range) / denom;
    if data_size <= relative_width {
        relative_width = data_size - 1;
    }
    let shift = if relative_width < LOG_MEAN_BIN_SIZE + LOG_MIN_SPLIT_COUNT {
        LOG_MEAN_BIN_SIZE + LOG_MIN_SPLIT_COUNT
    } else {
        relative_width
    };
    1usize << shift.min(31)
}

fn spread_bin_index(x: usize, min: usize, max: usize, bin_count: usize) -> usize {
    if max == min {
        0
    } else {
        (((x - min) as u128 * bin_count as u128 / (max - min) as u128) as usize)
            .min(bin_count.saturating_sub(1))
    }
}

fn spreadsort_rec(a: &mut [usize]) {
    let n = a.len();
    let max_count = get_max_count(rough_log2_size(a.iter().max().copied().unwrap_or(0)), n);
    if n < max_count {
        insertion_sort(a);
        return;
    }

    let min = *a.iter().min().unwrap();
    let max = *a.iter().max().unwrap();
    if min == max {
        return;
    }

    let log_range = rough_log2_size(max - min);
    let bin_count = (n / MEAN_BIN_SIZE).max(MIN_BIN_COUNT).min(n);
    let range = max - min;

    if bin_count >= range + 1 {
        insertion_sort(a);
        return;
    }

    let mut count = vec![0usize; bin_count];
    for &x in a.iter() {
        count[spread_bin_index(x, min, max, bin_count)] += 1;
    }

    let mut offset = vec![0usize; bin_count + 1];
    for i in 0..bin_count {
        offset[i + 1] = offset[i] + count[i];
    }

    let mut temp = vec![0usize; n];
    let mut cursor = offset.clone();
    for &x in a.iter() {
        let bin = spread_bin_index(x, min, max, bin_count);
        temp[cursor[bin]] = x;
        cursor[bin] += 1;
    }
    a.copy_from_slice(&temp);

    let fallback = get_max_count(log_range, n);
    for i in 0..bin_count {
        let start = offset[i];
        let end = offset[i + 1];
        let len = end - start;
        if len < 2 {
            continue;
        }
        if len < fallback {
            insertion_sort(&mut a[start..end]);
        } else {
            spreadsort_rec(&mut a[start..end]);
        }
    }
}

fn spread_sort(a: &mut [usize]) {
    if !a.is_empty() {
        spreadsort_rec(a);
    }
}
