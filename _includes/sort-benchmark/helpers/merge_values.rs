fn merge_values(left: &[usize], right: &[usize]) -> Vec<usize> {
    let mut out = Vec::with_capacity(left.len() + right.len());
    let (mut l, mut r) = (0, 0);
    while l < left.len() && r < right.len() {
        if left[l] <= right[r] {
            out.push(left[l]);
            l += 1;
        } else {
            out.push(right[r]);
            r += 1;
        }
    }
    out.extend_from_slice(&left[l..]);
    out.extend_from_slice(&right[r..]);
    out
}
