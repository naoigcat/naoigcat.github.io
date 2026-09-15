fileprivate func quick_random_pivot_next(_ state: inout UInt64) -> UInt64 {
    var s = state
    s ^= s << 13
    s ^= s >> 7
    s ^= s << 17
    state = s
    return s
}

fileprivate func quick_random_pivot_sort_range(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ lo: Int,
    _ hi: Int,
    _ rng: inout UInt64
) {
    if hi <= lo {
        return
    }
    if hi - lo < 16 {
        insertion_sort(UnsafeMutableBufferPointer(rebasing: a[lo..<(hi + 1)]))
        return
    }
    let pivot_idx = lo + Int(quick_random_pivot_next(&rng) % UInt64(hi - lo + 1))
    let p = partition_at(a, lo, hi, pivot_idx)
    if p > 0 {
        quick_random_pivot_sort_range(a, lo, p - 1, &rng)
    }
    quick_random_pivot_sort_range(a, p + 1, hi, &rng)
}

func quick_random_pivot_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { quick_random_pivot_sort($0) }
}

func quick_random_pivot_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count > 0 {
        let hi = a.count - 1
        var rng = UInt64(0x9e3779b97f4a7c15) ^ UInt64(a.count)
        quick_random_pivot_sort_range(a, 0, hi, &rng)
    }
}
