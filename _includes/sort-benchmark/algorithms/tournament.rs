fn tournament_winner(a: &[usize], left: usize, right: usize) -> usize {
    if left == usize::MAX {
        return right;
    }
    if right == usize::MAX {
        return left;
    }
    if a[left] <= a[right] {
        left
    } else {
        right
    }
}

fn tournament_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    let k = n.next_power_of_two();
    let mut tree = vec![0usize; 2 * k];
    for i in 0..k {
        tree[k + i] = if i < n { i } else { usize::MAX };
    }
    for i in (1..k).rev() {
        tree[i] = tournament_winner(a, tree[2 * i], tree[2 * i + 1]);
    }
    let mut out = vec![0usize; n];
    for pos in 0..n {
        let idx = tree[1];
        out[pos] = a[idx];
        a[idx] = usize::MAX;
        let mut node = k + idx;
        tree[node] = usize::MAX;
        while node > 1 {
            node /= 2;
            tree[node] = tournament_winner(a, tree[2 * node], tree[2 * node + 1]);
        }
    }
    a.copy_from_slice(&out);
}
