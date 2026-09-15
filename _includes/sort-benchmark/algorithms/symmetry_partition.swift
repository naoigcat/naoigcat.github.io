func sp_sort_range(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ hi: Int) {
    let P = 16
    if hi <= lo {
        return
    }
    if hi - lo < 16 {
        insertion_sort(UnsafeMutableBufferPointer(rebasing: a[lo..<(hi + 1)]))
        return
    }
    var s_end = lo
    while s_end < hi && hi - s_end > P * (s_end - lo + 1) {
        let chunk_end = min(s_end + P * (s_end - lo + 1), hi)
        sp_sort_range(a, lo, chunk_end)
        s_end = chunk_end
    }
    let median = lo + (s_end - lo) / 2
    let r_len = s_end - median
    let r_start = median + 1
    let r_dest = hi - r_len + 1
    for i in 0..<r_len {
        let from = r_start + i
        let to = r_dest + i
        if from != to {
            a.swapAt(from, to)
        }
    }
    let pivot = partition_at(a, lo, hi, median)
    if pivot > 0 {
        sp_sort_range(a, lo, pivot - 1)
    }
    sp_sort_range(a, pivot + 1, hi)
}

func symmetry_partition_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { symmetry_partition_sort($0) }
}

func symmetry_partition_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count > 0 {
        let hi = a.count - 1
        sp_sort_range(a, 0, hi)
    }
}
