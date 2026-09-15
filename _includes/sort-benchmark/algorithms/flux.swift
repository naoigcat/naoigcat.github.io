private let FLUX_INSERTION_THRESHOLD = 24

private func flux_is_sorted(_ a: UnsafeMutableBufferPointer<Int>) -> Bool {
    if a.count < 2 { return true }
    for i in 0..<(a.count - 1) {
        if a[i] > a[i + 1] { return false }
    }
    return true
}

private func flux_is_reverse_sorted(_ a: UnsafeMutableBufferPointer<Int>) -> Bool {
    if a.count < 2 { return true }
    for i in 0..<(a.count - 1) {
        if a[i] < a[i + 1] { return false }
    }
    return true
}

private func flux_reverse(_ a: UnsafeMutableBufferPointer<Int>) {
    var lo = 0
    var hi = a.count
    while lo + 1 < hi {
        hi -= 1
        a.swapAt(lo, hi)
        lo += 1
    }
}

private func flux_ordered_pairs(_ a: UnsafeMutableBufferPointer<Int>) -> Int {
    if a.count < 2 { return 0 }
    var c = 0
    for i in 0..<(a.count - 1) {
        if a[i] <= a[i + 1] { c += 1 }
    }
    return c
}

private func flux_median3_idx(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ i: Int,
    _ j: Int,
    _ k: Int
) -> Int {
    let (x, y, z) = (a[i], a[j], a[k])
    if x < y {
        if y < z {
            return j
        } else if x < z {
            return k
        } else {
            return i
        }
    } else if x < z {
        return i
    } else if y < z {
        return k
    } else {
        return j
    }
}

private func flux_quasimedian9(_ a: UnsafeMutableBufferPointer<Int>) -> Int {
    let n = a.count
    if n < 9 {
        return a[n / 2]
    }
    let step = n / 8
    let i0 = 0
    let i1 = step
    let i2 = step * 2
    let i3 = step * 3
    let i4 = step * 4
    let i5 = step * 5
    let i6 = step * 6
    let i7 = step * 7
    let i8 = n - 1
    let m0 = flux_median3_idx(a, i0, i1, i2)
    let m1 = flux_median3_idx(a, i3, i4, i5)
    let m2 = flux_median3_idx(a, i6, i7, i8)
    return a[flux_median3_idx(a, m0, m1, m2)]
}

private func flux_merge(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ swap: UnsafeMutableBufferPointer<Int>
) {
    let n = a.count
    if n <= 1 {
        return
    }
    let mid = n / 2
    flux_merge(UnsafeMutableBufferPointer(rebasing: a[0..<mid]), swap)
    flux_merge(UnsafeMutableBufferPointer(rebasing: a[mid..<n]), swap)
    var i = 0
    var j = 0
    var k = 0
    let leftLen = mid
    let rightLen = n - mid
    while i < leftLen && j < rightLen {
        if a[i] <= a[mid + j] {
            swap[k] = a[i]
            i += 1
        } else {
            swap[k] = a[mid + j]
            j += 1
        }
        k += 1
    }
    while i < leftLen {
        swap[k] = a[i]
        i += 1
        k += 1
    }
    while j < rightLen {
        swap[k] = a[mid + j]
        j += 1
        k += 1
    }
    for idx in 0..<n {
        a[idx] = swap[idx]
    }
}

private func flux_stable_partition(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ swap: UnsafeMutableBufferPointer<Int>,
    _ pivot: Int
) -> Int {
    let n = a.count
    for i in 0..<n {
        swap[i] = a[i]
    }
    var left = 0
    for i in 0..<n {
        if swap[i] <= pivot {
            left += 1
        }
    }
    var l = 0
    var r = left
    for i in 0..<n {
        let x = swap[i]
        if x <= pivot {
            a[l] = x
            l += 1
        } else {
            a[r] = x
            r += 1
        }
    }
    return left
}

private func flux_partition_sort(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ swap: UnsafeMutableBufferPointer<Int>
) {
    let n = a.count
    if n <= 1 {
        return
    }
    if n < FLUX_INSERTION_THRESHOLD {
        insertion_sort(a)
        return
    }

    let pivot = flux_quasimedian9(a)
    let left = flux_stable_partition(a, swap, pivot)
    let right = n - left

    if right == 0 {
        for i in 0..<n {
            swap[i] = a[i]
        }
        var lt = 0
        for i in 0..<n {
            if swap[i] < pivot {
                a[lt] = swap[i]
                lt += 1
            }
        }
        var eq = lt
        for i in 0..<n {
            if swap[i] == pivot {
                a[eq] = swap[i]
                eq += 1
            }
        }
        if lt > 1 {
            flux_partition_sort(UnsafeMutableBufferPointer(rebasing: a[0..<lt]), swap)
        }
        return
    }

    let unbalanced = left > 0 && (left < n / 16 || right < n / 16)

    if unbalanced {
        flux_merge(UnsafeMutableBufferPointer(rebasing: a[0..<left]), swap)
        flux_merge(UnsafeMutableBufferPointer(rebasing: a[left..<n]), swap)
        return
    }

    if left > 1 {
        flux_partition_sort(UnsafeMutableBufferPointer(rebasing: a[0..<left]), swap)
    }
    if right > 1 {
        flux_partition_sort(UnsafeMutableBufferPointer(rebasing: a[left..<n]), swap)
    }
}

private func flux_analyze(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ swap: UnsafeMutableBufferPointer<Int>
) -> Bool {
    let n = a.count
    if n <= 1 {
        return true
    }
    if flux_is_sorted(a) {
        return true
    }
    if flux_is_reverse_sorted(a) {
        flux_reverse(a)
        return true
    }

    let q = n / 4
    if q >= 2 {
        let bounds = [0, q, q * 2, q * 3, n]
        for s in 0..<4 {
            let lo = bounds[s]
            let hi = bounds[s + 1]
            if hi - lo < 2 {
                continue
            }
            let pairs = hi - lo - 1
            if flux_ordered_pairs(UnsafeMutableBufferPointer(rebasing: a[lo..<hi])) * 2 > pairs {
                flux_merge(UnsafeMutableBufferPointer(rebasing: a[lo..<hi]), swap)
            }
        }
        if flux_is_sorted(a) {
            return true
        }
    }
    return false
}

func flux_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { flux_sort($0) }
}

func flux_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    var swapStorage = [Int](repeating: 0, count: n)
    swapStorage.withUnsafeMutableBufferPointer { swap in
        if flux_analyze(a, swap) {
            return
        }
        flux_partition_sort(a, swap)
    }
}
