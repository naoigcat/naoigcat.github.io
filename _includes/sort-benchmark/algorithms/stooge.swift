func stooge_sort_range(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ hi: Int) {
    if a[lo] > a[hi] {
        a.swapAt(lo, hi)
    }
    if hi - lo + 1 <= 2 {
        return
    }
    let t = (hi - lo + 1) / 3
    stooge_sort_range(a, lo, hi - t)
    stooge_sort_range(a, lo + t, hi)
    stooge_sort_range(a, lo, hi - t)
}

func stooge_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { stooge_sort($0) }
}

func stooge_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count <= 1 {
        return
    }
    stooge_sort_range(a, 0, a.count - 1)
}
