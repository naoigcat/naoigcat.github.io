func slow_sort_range(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ hi: Int) {
    if lo >= hi {
        return
    }
    let m = (lo + hi) / 2
    slow_sort_range(a, lo, m)
    slow_sort_range(a, m + 1, hi)
    if a[m] > a[hi] {
        a.swapAt(m, hi)
    }
    slow_sort_range(a, lo, hi - 1)
}

func slow_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { slow_sort($0) }
}

func slow_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count <= 1 {
        return
    }
    slow_sort_range(a, 0, a.count - 1)
}
