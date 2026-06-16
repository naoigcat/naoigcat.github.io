fn ford_johnson_insert_order(m: usize) -> Vec<usize> {
    if m == 0 {
        return Vec::new();
    }
    let mut js = vec![0usize, 1];
    while *js.last().unwrap() < m {
        let l = js.len();
        js.push(js[l - 1] + 2 * js[l - 2]);
    }
    let mut order = Vec::new();
    let mut used = vec![false; m];
    let mut prev_j = 0usize;
    for &j in js.iter().skip(1) {
        if j > m {
            break;
        }
        if j > prev_j {
            for idx in (prev_j..=j - 1).rev() {
                if idx < m && !used[idx] {
                    order.push(idx);
                    used[idx] = true;
                }
            }
            prev_j = j;
        }
    }
    for idx in (0..m).rev() {
        if !used[idx] {
            order.push(idx);
        }
    }
    order
}

fn ford_johnson_reorder_pairs(
    pairs: &[(usize, usize)],
    sorted_larges: &[usize],
) -> Vec<(usize, usize)> {
    let mut out = Vec::with_capacity(sorted_larges.len());
    let mut taken = vec![false; pairs.len()];
    for &lg in sorted_larges {
        for (i, p) in pairs.iter().enumerate() {
            if !taken[i] && p.1 == lg {
                out.push(*p);
                taken[i] = true;
                break;
            }
        }
    }
    out
}

fn ford_johnson(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    if n == 2 {
        if a[0] > a[1] {
            a.swap(0, 1);
        }
        return;
    }
    let pair_count = n / 2;
    let mut pairs: Vec<(usize, usize)> = Vec::with_capacity(pair_count);
    for i in 0..pair_count {
        let lo = 2 * i;
        let hi = lo + 1;
        if a[lo] > a[hi] {
            pairs.push((a[hi], a[lo]));
        } else {
            pairs.push((a[lo], a[hi]));
        }
    }
    let odd = if n % 2 == 1 { Some(a[n - 1]) } else { None };
    let mut larges: Vec<usize> = pairs.iter().map(|p| p.1).collect();
    ford_johnson(&mut larges);
    let sorted_pairs = ford_johnson_reorder_pairs(&pairs, &larges);
    let mut chain = Vec::with_capacity(n);
    chain.push(sorted_pairs[0].0);
    chain.extend(sorted_pairs.iter().map(|p| p.1));
    let mut pending_pairs: Vec<(usize, usize)> =
        sorted_pairs.iter().skip(1).copied().collect();
    if let Some(v) = odd {
        pending_pairs.push((v, usize::MAX));
    }
    let pending: Vec<usize> = pending_pairs.iter().map(|p| p.0).collect();
    for idx in ford_johnson_insert_order(pending.len()) {
        let val = pending[idx];
        let limit = if pending_pairs[idx].1 == usize::MAX {
            chain.len()
        } else {
            chain
                .iter()
                .position(|&x| x == pending_pairs[idx].1)
                .unwrap_or(chain.len())
        };
        let pos = chain[..limit].partition_point(|&x| x < val);
        chain.insert(pos, val);
    }
    a.copy_from_slice(&chain);
}
