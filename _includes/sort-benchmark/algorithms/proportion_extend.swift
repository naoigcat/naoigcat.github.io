fileprivate func pe_sort_range(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ hi: Int) {
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
        pe_sort_range(a, lo, chunk_end)
        s_end = chunk_end
    }
    let median = lo + (s_end - lo) / 2
    let pivot = partition_at(a, lo, hi, median)
    if pivot > 0 {
        pe_sort_range(a, lo, pivot - 1)
    }
    pe_sort_range(a, pivot + 1, hi)
}

func proportion_extend_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { proportion_extend_sort($0) }
}

func proportion_extend_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count > 0 {
        let hi = a.count - 1
        pe_sort_range(a, 0, hi)
    }
}
