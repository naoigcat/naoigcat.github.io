func three_way_quick_sort_range(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ hi: Int) {
    if hi <= lo {
        return
    }
    if hi - lo < 16 {
        insertion_sort(UnsafeMutableBufferPointer(rebasing: a[lo..<(hi + 1)]))
        return
    }

    let pivot = a[lo]
    var lt = lo
    var i = lo + 1
    var gt = hi

    while i <= gt {
        if a[i] < pivot {
            a.swapAt(lt, i)
            lt += 1
            i += 1
        } else if a[i] > pivot {
            a.swapAt(i, gt)
            gt -= 1
        } else {
            i += 1
        }
    }

    if lt > lo {
        three_way_quick_sort_range(a, lo, lt - 1)
    }
    if gt < hi {
        three_way_quick_sort_range(a, gt + 1, hi)
    }
}

func three_way_quick_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { three_way_quick_sort($0) }
}

func three_way_quick_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count > 0 {
        let hi = a.count - 1
        three_way_quick_sort_range(a, 0, hi)
    }
}
