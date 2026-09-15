fileprivate func quick_hoare_partition(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ hi: Int) -> Int {
    let pivot = a[lo + (hi - lo) / 2]
    var i = lo - 1
    var j = hi + 1
    while true {
        while true {
            i += 1
            if a[i] >= pivot {
                break
            }
        }
        while true {
            j -= 1
            if a[j] <= pivot {
                break
            }
        }
        if i >= j {
            return j
        }
        a.swapAt(i, j)
    }
}

fileprivate func quick_hoare_sort_range(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ hi: Int) {
    if hi <= lo {
        return
    }
    if hi - lo < 16 {
        insertion_sort(UnsafeMutableBufferPointer(rebasing: a[lo..<(hi + 1)]))
        return
    }
    let p = quick_hoare_partition(a, lo, hi)
    quick_hoare_sort_range(a, lo, p)
    quick_hoare_sort_range(a, p + 1, hi)
}

func quick_hoare_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { quick_hoare_sort($0) }
}

func quick_hoare_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count > 0 {
        let hi = a.count - 1
        quick_hoare_sort_range(a, 0, hi)
    }
}
