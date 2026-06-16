fn cartesian_tree_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    let mut left = vec![None; n];
    let mut right = vec![None; n];
    let mut stack = Vec::new();
    for i in 0..n {
        let mut last = None;
        while stack.last().is_some_and(|&top| a[top] > a[i]) {
            last = stack.pop();
        }
        if let Some(&top) = stack.last() {
            right[top] = Some(i);
        }
        if let Some(last_idx) = last {
            left[i] = Some(last_idx);
        }
        stack.push(i);
    }
    fn extract(
        node: Option<usize>,
        a: &[usize],
        left: &[Option<usize>],
        right: &[Option<usize>],
    ) -> Vec<usize> {
        if let Some(i) = node {
            let l = extract(left[i], a, left, right);
            let r = extract(right[i], a, left, right);
            let merged = merge_values(&l, &r);
            let mut out = Vec::with_capacity(merged.len() + 1);
            out.push(a[i]);
            out.extend(merged);
            out
        } else {
            Vec::new()
        }
    }
    let root = stack.first().copied();
    let out = extract(root, a, &left, &right);
    a.copy_from_slice(&out);
}
