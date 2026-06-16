fn partition(a: &mut [usize], lo: usize, hi: usize) -> usize {
    partition_at(a, lo, hi, lo + (hi - lo) / 2)
}
