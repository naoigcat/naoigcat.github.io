/// Branching factor for multiway (k-way) merge sort. Fixed for the pedagogical
/// benchmark so asymptotics stay Θ(n log n) with a constant-factor log_k.
const WAY: usize = 4;

/// Stable k-way merge: when heads compare equal, the leftmost run wins.
fn merge_k_way(runs: &[&[usize]]) -> Vec<usize> {
    let k = runs.len();
    let mut heads = vec![0usize; k];
    let total: usize = runs.iter().map(|r| r.len()).sum();
    let mut out = Vec::with_capacity(total);

    loop {
        let mut best: Option<(usize, usize)> = None; // (run_index, value)
        for i in 0..k {
            if heads[i] < runs[i].len() {
                let v = runs[i][heads[i]];
                match best {
                    None => best = Some((i, v)),
                    Some((bi, bv)) => {
                        if v < bv || (v == bv && i < bi) {
                            best = Some((i, v));
                        }
                    }
                }
            }
        }
        match best {
            None => break,
            Some((i, v)) => {
                out.push(v);
                heads[i] += 1;
            }
        }
    }
    out
}

fn multiway_merge_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }

    let mut bounds: Vec<(usize, usize)> = Vec::with_capacity(WAY);
    let base = n / WAY;
    let rem = n % WAY;
    let mut start = 0usize;
    for i in 0..WAY {
        let len = base + usize::from(i < rem);
        if len == 0 {
            continue;
        }
        let end = start + len;
        multiway_merge_sort(&mut a[start..end]);
        bounds.push((start, end));
        start = end;
    }

    if bounds.len() <= 1 {
        return;
    }

    let runs: Vec<Vec<usize>> = bounds
        .iter()
        .map(|&(lo, hi)| a[lo..hi].to_vec())
        .collect();
    let refs: Vec<&[usize]> = runs.iter().map(|r| r.as_slice()).collect();
    let merged = merge_k_way(&refs);
    a.copy_from_slice(&merged);
}
