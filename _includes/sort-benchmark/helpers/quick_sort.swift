func quick_sort_range(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ hi: Int) {
    if hi <= lo {
        return
    }
    if hi - lo < 16 {
        insertion_sort(UnsafeMutableBufferPointer(rebasing: a[lo..<(hi + 1)]))
        return
    }
    let p = partition(a, lo, hi)
    if p > 0 {
        quick_sort_range(a, lo, p - 1)
    }
    quick_sort_range(a, p + 1, hi)
}

func quick_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { quick_sort($0) }
}

func quick_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count > 0 {
        let hi = a.count - 1
        quick_sort_range(a, 0, hi)
    }
}
