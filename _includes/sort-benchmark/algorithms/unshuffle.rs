fn merge_two_sorted(left: &[usize], right: &[usize]) -> Vec<usize> {
    let mut out = Vec::with_capacity(left.len() + right.len());
    let mut i = 0;
    let mut j = 0;
    while i < left.len() && j < right.len() {
        if left[i] <= right[j] {
            out.push(left[i]);
            i += 1;
        } else {
            out.push(right[j]);
            j += 1;
        }
    }
    out.extend_from_slice(&left[i..]);
    out.extend_from_slice(&right[j..]);
    out
}

fn unshuffle_sort(a: &mut [usize]) {
    let mut piles: Vec<Vec<usize>> = Vec::new();

    for &x in a.iter() {
        let mut placed = false;
        for pile in piles.iter_mut() {
            let front = pile[0];
            let back = *pile.last().unwrap();
            if x <= front {
                pile.insert(0, x);
                placed = true;
                break;
            } else if x >= back {
                pile.push(x);
                placed = true;
                break;
            }
        }
        if !placed {
            piles.push(vec![x]);
        }
    }

    if piles.is_empty() {
        return;
    }

    let mut merged = piles[0].clone();
    for pile in piles.into_iter().skip(1) {
        merged = merge_two_sorted(&merged, &pile);
    }

    a.copy_from_slice(&merged);
}
