fn spaghetti_sort(a: &mut [usize]) {
    let n = a.len();
    if n < 2 {
        return;
    }

    // Physical model: remove the longest remaining stick repeatedly (descending),
    // then reverse for ascending order. Digital simulation uses O(n) scratch space.
    let mut sticks: Vec<usize> = a.to_vec();
    let mut descending: Vec<usize> = Vec::with_capacity(n);

    while !sticks.is_empty() {
        let mut max_idx = 0;
        for i in 1..sticks.len() {
            if sticks[i] > sticks[max_idx] {
                max_idx = i;
            }
        }
        descending.push(sticks.swap_remove(max_idx));
    }

    descending.reverse();
    a.copy_from_slice(&descending);
}
