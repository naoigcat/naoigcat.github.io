fn patience_sort(a: &mut [usize]) {
    let mut piles: Vec<Vec<usize>> = Vec::new();
    for &value in a.iter() {
        let mut lo = 0;
        let mut hi = piles.len();
        while lo < hi {
            let mid = (lo + hi) / 2;
            if *piles[mid].last().unwrap() >= value {
                hi = mid;
            } else {
                lo = mid + 1;
            }
        }
        if lo == piles.len() {
            piles.push(vec![value]);
        } else {
            piles[lo].push(value);
        }
    }
    for slot in a.iter_mut() {
        let mut min = 0;
        for i in 1..piles.len() {
            if piles[i].last().is_some()
                && (piles[min].last().is_none()
                    || piles[i].last().unwrap() < piles[min].last().unwrap())
            {
                min = i;
            }
        }
        *slot = piles[min].pop().unwrap();
    }
}
