fileprivate func intro_sort_range(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ lo: Int,
    _ hi: Int,
    _ depth: Int
) {
    if hi <= lo {
        return
    }
    if hi - lo < 16 {
        insertion_sort(UnsafeMutableBufferPointer(rebasing: a[lo..<(hi + 1)]))
        return
    }
    if depth == 0 {
        heap_sort(UnsafeMutableBufferPointer(rebasing: a[lo..<(hi + 1)]))
        return
    }
    let p = partition(a, lo, hi)
    if p > 0 {
        intro_sort_range(a, lo, p - 1, depth - 1)
    }
    intro_sort_range(a, p + 1, hi, depth - 1)
}

func intro_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { intro_sort($0) }
}

func intro_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count > 0 {
        let hi = a.count - 1
        let depth = Int.bitWidth - a.count.leadingZeroBitCount
        intro_sort_range(a, 0, hi, depth * 2)
    }
}
