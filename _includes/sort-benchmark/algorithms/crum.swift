/// Educational stand-in for scandum's crumsort (fulcrum partition + rotate merge).

private let CRUM_SWAP = 512
private let CRUM_INSERTION_THRESHOLD = 24

private func crum_is_sorted(_ a: UnsafeMutableBufferPointer<Int>) -> Bool {
    if a.count < 2 { return true }
    for i in 0..<(a.count - 1) {
        if a[i] > a[i + 1] { return false }
    }
    return true
}

private func crum_is_reverse_sorted(_ a: UnsafeMutableBufferPointer<Int>) -> Bool {
    if a.count < 2 { return true }
    for i in 0..<(a.count - 1) {
        if a[i] < a[i + 1] { return false }
    }
    return true
}

private func crum_reverse(_ a: UnsafeMutableBufferPointer<Int>) {
    var lo = 0
    var hi = a.count
    while lo + 1 < hi {
        hi -= 1
        a.swapAt(lo, hi)
        lo += 1
    }
}

private func crum_ordered_pairs(_ a: UnsafeMutableBufferPointer<Int>) -> Int {
    if a.count < 2 { return 0 }
    var c = 0
    for i in 0..<(a.count - 1) {
        if a[i] <= a[i + 1] { c += 1 }
    }
    return c
}

private func crum_median3_idx(
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

private func crum_quasimedian9(_ a: UnsafeMutableBufferPointer<Int>) -> Int {
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
    let m0 = crum_median3_idx(a, i0, i1, i2)
    let m1 = crum_median3_idx(a, i3, i4, i5)
    let m2 = crum_median3_idx(a, i6, i7, i8)
    return a[crum_median3_idx(a, m0, m1, m2)]
}

private func crum_rotate(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ left: Int,
    _ swap: UnsafeMutableBufferPointer<Int>
) {
    let n = a.count
    if left == 0 || left == n {
        return
    }
    let right = n - left
    let swap_cap = swap.count

    if left <= right {
        if left <= swap_cap {
            for i in 0..<left {
                swap[i] = a[i]
            }
            for i in 0..<right {
                a[i] = a[left + i]
            }
            for i in 0..<left {
                a[right + i] = swap[i]
            }
            return
        }
    } else if right <= swap_cap {
        for i in 0..<right {
            swap[i] = a[left + i]
        }
        for i in stride(from: left - 1, through: 0, by: -1) {
            a[i + right] = a[i]
        }
        for i in 0..<right {
            a[i] = swap[i]
        }
        return
    }

    // three reverses
    var lo = 0
    var hi = left
    while lo + 1 < hi {
        hi -= 1
        a.swapAt(lo, hi)
        lo += 1
    }
    lo = left
    hi = n
    while lo + 1 < hi {
        hi -= 1
        a.swapAt(lo, hi)
        lo += 1
    }
    lo = 0
    hi = n
    while lo + 1 < hi {
        hi -= 1
        a.swapAt(lo, hi)
        lo += 1
    }
}

private func crum_lower_bound(_ hay: UnsafeMutableBufferPointer<Int>, _ needle: Int) -> Int {
    var lo = 0
    var hi = hay.count
    while lo < hi {
        let mid = lo + (hi - lo) / 2
        if hay[mid] < needle {
            lo = mid + 1
        } else {
            hi = mid
        }
    }
    return lo
}

private func crum_merge_with_swap(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ mid: Int,
    _ swap: UnsafeMutableBufferPointer<Int>
) {
    let n = a.count
    for i in 0..<mid {
        swap[i] = a[i]
    }
    var i = 0
    var j = mid
    var k = 0
    while i < mid && j < n {
        if swap[i] <= a[j] {
            a[k] = swap[i]
            i += 1
        } else {
            a[k] = a[j]
            j += 1
        }
        k += 1
    }
    while i < mid {
        a[k] = swap[i]
        i += 1
        k += 1
    }
}

private func crum_rotate_merge_block(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ left_len: Int,
    _ right_len: Int,
    _ swap: UnsafeMutableBufferPointer<Int>
) {
    if left_len == 0 || right_len == 0 {
        return
    }
    if a[left_len - 1] <= a[left_len] {
        return
    }

    let total = left_len + right_len
    let swap_cap = swap.count
    if total <= swap_cap {
        crum_merge_with_swap(a, left_len, swap)
        return
    }
    if left_len <= swap_cap {
        crum_merge_with_swap(a, left_len, swap)
        return
    }
    if right_len <= swap_cap {
        for i in 0..<right_len {
            swap[i] = a[left_len + i]
        }
        var i = left_len
        var j = right_len
        var k = total
        while i > 0 && j > 0 {
            if a[i - 1] > swap[j - 1] {
                k -= 1
                i -= 1
                a[k] = a[i]
            } else {
                k -= 1
                j -= 1
                a[k] = swap[j]
            }
        }
        while j > 0 {
            k -= 1
            j -= 1
            a[k] = swap[j]
        }
        return
    }

    let rblock = left_len / 2
    let lblock = left_len - rblock
    let center = a[lblock]
    let left = crum_lower_bound(
        UnsafeMutableBufferPointer(rebasing: a[left_len..<total]),
        center
    )
    let right = right_len - left

    if left > 0 {
        crum_rotate(
            UnsafeMutableBufferPointer(rebasing: a[lblock..<(lblock + rblock + left)]),
            rblock,
            swap
        )
        crum_rotate_merge_block(a, lblock, left, swap)
        crum_rotate_merge_block(
            UnsafeMutableBufferPointer(rebasing: a[(lblock + left)..<total]),
            rblock,
            right,
            swap
        )
    } else if right > 0 {
        crum_rotate_merge_block(
            UnsafeMutableBufferPointer(rebasing: a[lblock..<total]),
            rblock,
            right,
            swap
        )
    }
}

private func crum_rotate_mergesort(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ swap: UnsafeMutableBufferPointer<Int>
) {
    let n = a.count
    if n <= 1 {
        return
    }
    let block0 = max(min(CRUM_INSERTION_THRESHOLD, swap.count), 1)
    var i = 0
    while i < n {
        let end = min(i + block0, n)
        insertion_sort(UnsafeMutableBufferPointer(rebasing: a[i..<end]))
        i = end
    }
    var block = block0
    while block < n {
        var start = 0
        while start < n {
            let mid = start + block
            if mid >= n {
                break
            }
            let end = min(mid + block, n)
            let left_len = mid - start
            let right_len = end - mid
            crum_rotate_merge_block(
                UnsafeMutableBufferPointer(rebasing: a[start..<end]),
                left_len,
                right_len,
                swap
            )
            start = end
        }
        let next = block &* 2
        if next == 0 || next / 2 != block {
            break
        }
        block = next
    }
}

private func crum_fulcrum_partition(_ a: UnsafeMutableBufferPointer<Int>, _ pivot: Int) -> Int {
    let n = a.count

    var pivot_idx = 0
    for i in 0..<n {
        if a[i] == pivot {
            pivot_idx = i
            break
        }
    }
    a.swapAt(0, pivot_idx)

    let pivot_val = a[0]
    var head = 0
    var tail = n - 1

    while true {
        while head < tail && a[tail] > pivot_val {
            tail -= 1
        }
        if head >= tail {
            a[head] = pivot_val
            return head
        }
        a[head] = a[tail]
        head += 1

        while head < tail && a[head] <= pivot_val {
            head += 1
        }
        if head >= tail {
            a[head] = pivot_val
            return head
        }
        a[tail] = a[head]
        tail -= 1
    }
}

private func crum_partition_sort(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ swap: UnsafeMutableBufferPointer<Int>
) {
    let n = a.count
    if n <= 1 {
        return
    }
    if n < CRUM_INSERTION_THRESHOLD {
        insertion_sort(a)
        return
    }

    let pivot = crum_quasimedian9(a)
    let mid = crum_fulcrum_partition(a, pivot)
    let left_len = mid
    let right_len = n - mid - 1

    if right_len == 0 {
        var lt = 0
        for i in 0..<n {
            if a[i] < pivot {
                a.swapAt(lt, i)
                lt += 1
            }
        }
        if lt > 1 {
            crum_partition_sort(UnsafeMutableBufferPointer(rebasing: a[0..<lt]), swap)
        }
        return
    }

    let unbalanced = (left_len > 0 && left_len < n / 16)
        || (right_len > 0 && right_len < n / 16)

    if unbalanced {
        if left_len > 1 {
            crum_rotate_mergesort(UnsafeMutableBufferPointer(rebasing: a[0..<left_len]), swap)
        }
        if right_len > 1 {
            crum_rotate_mergesort(UnsafeMutableBufferPointer(rebasing: a[(mid + 1)..<n]), swap)
        }
        return
    }

    if left_len > 1 {
        crum_partition_sort(UnsafeMutableBufferPointer(rebasing: a[0..<left_len]), swap)
    }
    if right_len > 1 {
        crum_partition_sort(UnsafeMutableBufferPointer(rebasing: a[(mid + 1)..<n]), swap)
    }
}

private func crum_analyze(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ swap: UnsafeMutableBufferPointer<Int>
) -> Bool {
    let n = a.count
    if n <= 1 {
        return true
    }
    if crum_is_sorted(a) {
        return true
    }
    if crum_is_reverse_sorted(a) {
        crum_reverse(a)
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
            if crum_ordered_pairs(UnsafeMutableBufferPointer(rebasing: a[lo..<hi])) * 2 > pairs {
                crum_rotate_mergesort(UnsafeMutableBufferPointer(rebasing: a[lo..<hi]), swap)
            }
        }
        if crum_is_sorted(a) {
            return true
        }
    }
    return false
}

func crum_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { crum_sort($0) }
}

func crum_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    var swapStorage = [Int](repeating: 0, count: CRUM_SWAP)
    swapStorage.withUnsafeMutableBufferPointer { swap in
        if crum_analyze(a, swap) {
            return
        }
        crum_partition_sort(a, swap)
    }
}
