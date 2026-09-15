func sym_swap_range(_ a: UnsafeMutableBufferPointer<Int>, _ left: Int, _ right: Int, _ n: Int) {
    for i in 0..<n {
        a.swapAt(left + i, right + i)
    }
}

/// Rotate consecutive blocks `a[lo..<mid]` and `a[mid..<hi]` into `a[lo..<hi]` as
/// `v` then `u` (half-open indices), using block swaps only.
func sym_rotate(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ mid: Int, _ hi: Int) {
    var i = mid - lo
    var j = hi - mid
    while i != j {
        if i > j {
            sym_swap_range(a, mid - i, mid, j)
            i -= j
        } else {
            sym_swap_range(a, mid - i, mid + j - i, i)
            j -= i
        }
    }
    sym_swap_range(a, mid - i, mid, i)
}

/// Kim–Kutzner SymMerge of adjacent sorted runs `a[left..<mid]` and `a[mid..<right]`.
/// Assumes `left < mid < right` (half-open).
func sym_merge(_ a: UnsafeMutableBufferPointer<Int>, _ left: Int, _ mid: Int, _ right: Int) {
    if mid - left == 1 {
        var i = mid
        var j = right
        while i < j {
            let h = (i + j) / 2
            if a[h] < a[left] {
                i = h + 1
            } else {
                j = h
            }
        }
        let end = i > 0 ? i - 1 : 0
        if left <= end {
            for k in left...end {
                a.swapAt(k, k + 1)
            }
        }
        return
    }

    if right - mid == 1 {
        var i = left
        var j = mid
        while i < j {
            let h = (i + j) / 2
            if a[mid] >= a[h] {
                i = h + 1
            } else {
                j = h
            }
        }
        var k = mid
        while k > i {
            a.swapAt(k, k - 1)
            k -= 1
        }
        return
    }

    let center = (left + right) / 2
    let n = center + mid
    var start: Int
    var r: Int
    if mid > center {
        start = n - right
        r = center
    } else {
        start = left
        r = mid
    }
    let p = n - 1

    while start < r {
        let c = (start + r) / 2
        if a[p - c] >= a[c] {
            start = c + 1
        } else {
            r = c
        }
    }

    let end = n - start
    if start < mid && mid < end {
        sym_rotate(a, start, mid, end)
    }
    if left < start && start < center {
        sym_merge(a, left, start, center)
    }
    if center < end && end < right {
        sym_merge(a, center, end, right)
    }
}

func sym_merge_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { sym_merge_sort($0) }
}

func sym_merge_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }

    let BLOCK = 20
    var start = 0
    while start < n {
        let end = min(start + BLOCK, n)
        insertion_sort(UnsafeMutableBufferPointer(rebasing: a[start..<end]))
        start = end
    }

    var width = BLOCK
    while width < n {
        var lo = 0
        while lo + width < n {
            let mid = lo + width
            let hi = min(lo + 2 * width, n)
            sym_merge(a, lo, mid, hi)
            lo = hi
        }
        width *= 2
    }
}
