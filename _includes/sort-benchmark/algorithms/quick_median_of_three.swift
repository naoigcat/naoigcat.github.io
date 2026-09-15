fileprivate func quick_median_of_three_idx(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ hi: Int) -> Int {
    let mid = lo + (hi - lo) / 2
    let x = a[lo]
    let y = a[mid]
    let z = a[hi]
    if (x <= y && y <= z) || (z <= y && y <= x) {
        return mid
    } else if (y <= x && x <= z) || (z <= x && x <= y) {
        return lo
    } else {
        return hi
    }
}

fileprivate func quick_median_of_three_sort_range(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ hi: Int) {
    if hi <= lo {
        return
    }
    if hi - lo < 16 {
        insertion_sort(UnsafeMutableBufferPointer(rebasing: a[lo..<(hi + 1)]))
        return
    }
    let pivot_idx = quick_median_of_three_idx(a, lo, hi)
    let p = partition_at(a, lo, hi, pivot_idx)
    if p > 0 {
        quick_median_of_three_sort_range(a, lo, p - 1)
    }
    quick_median_of_three_sort_range(a, p + 1, hi)
}

func quick_median_of_three_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { quick_median_of_three_sort($0) }
}

func quick_median_of_three_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count > 0 {
        let hi = a.count - 1
        quick_median_of_three_sort_range(a, 0, hi)
    }
}
