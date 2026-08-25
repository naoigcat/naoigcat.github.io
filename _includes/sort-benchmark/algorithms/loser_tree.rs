fn player_key(a: &[usize], idx: usize) -> usize {
    if idx == usize::MAX {
        usize::MAX
    } else {
        a[idx]
    }
}

fn loser_and_winner(a: &[usize], left: usize, right: usize) -> (usize, usize) {
    match (left, right) {
        (usize::MAX, r) => (usize::MAX, r),
        (l, usize::MAX) => (usize::MAX, l),
        (l, r) => {
            if player_key(a, l) <= player_key(a, r) {
                (r, l)
            } else {
                (l, r)
            }
        }
    }
}

fn adjust_loser_tree(a: &[usize], ls: &mut [usize], k: usize, mut s: usize) {
    let mut t = (s + k) / 2;
    while t > 0 {
        if player_key(a, s) > player_key(a, ls[t]) {
            core::mem::swap(&mut s, &mut ls[t]);
        }
        t /= 2;
    }
    ls[0] = s;
}

fn loser_tree_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    let k = n.next_power_of_two();
    let mut ls = vec![usize::MAX; k];
    let mut winner = vec![usize::MAX; 2 * k];
    for i in 0..k {
        winner[k + i] = if i < n { i } else { usize::MAX };
    }
    for i in (1..k).rev() {
        let (loser, win) = loser_and_winner(a, winner[2 * i], winner[2 * i + 1]);
        ls[i] = loser;
        winner[i] = win;
    }
    ls[0] = winner[1];

    let mut out = vec![0usize; n];
    for pos in 0..n {
        let idx = ls[0];
        out[pos] = a[idx];
        a[idx] = usize::MAX;
        adjust_loser_tree(a, &mut ls, k, idx);
    }
    a.copy_from_slice(&out);
}
