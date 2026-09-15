private func dual_pivot_quick_sort_range(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ hi: Int) {
    if hi <= lo {
        return
    }
    if hi - lo < 16 {
        insertion_sort(UnsafeMutableBufferPointer(rebasing: a[lo..<(hi + 1)]))
        return
    }

    if a[lo] > a[hi] {
        a.swapAt(lo, hi)
    }
    let pivot1 = a[lo]
    let pivot2 = a[hi]

    var less = lo + 1
    var great = hi - 1
    var k = less

    while k <= great {
        if a[k] < pivot1 {
            a.swapAt(k, less)
            less += 1
            k += 1
        } else if a[k] > pivot2 {
            while k < great && a[great] > pivot2 {
                great -= 1
            }
            a.swapAt(k, great)
            great -= 1
            if a[k] < pivot1 {
                a.swapAt(k, less)
                less += 1
            }
            k += 1
        } else {
            k += 1
        }
    }

    a.swapAt(lo, less - 1)
    a.swapAt(hi, great + 1)

    if lo + 1 < less {
        dual_pivot_quick_sort_range(a, lo, less - 2)
    }
    if less < great {
        dual_pivot_quick_sort_range(a, less, great)
    }
    if great + 1 < hi {
        dual_pivot_quick_sort_range(a, great + 2, hi)
    }
}

func dual_pivot_quick_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { dual_pivot_quick_sort($0) }
}

func dual_pivot_quick_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count >= 1 {
        dual_pivot_quick_sort_range(a, 0, a.count - 1)
    }
}
