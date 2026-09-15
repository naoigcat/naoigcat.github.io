/// Educational stand-in for scandum's blitsort (rotate merge / rotate quick).
/// Production uses trinity rotations, monobound binary search, quadsort blocks,
/// and branchless partitioning; here those are replaced with clearer routines
/// and a fixed swap of `BLIT_SWAP` elements (default 512, as in the reference).

let BLIT_SWAP = 512
let BLIT_OUT = 24

func blit_reverse_range(_ a: UnsafeMutableBufferPointer<Int>) {
    var lo = 0
    var hi = a.count
    while lo + 1 < hi {
        hi -= 1
        a.swapAt(lo, hi)
        lo += 1
    }
}

func blit_is_sorted(_ a: UnsafeMutableBufferPointer<Int>) -> Bool {
    if a.count < 2 {
        return true
    }
    for i in 1..<a.count {
        if a[i - 1] > a[i] {
            return false
        }
    }
    return true
}

func blit_is_reverse_sorted(_ a: UnsafeMutableBufferPointer<Int>) -> Bool {
    if a.count < 2 {
        return true
    }
    for i in 1..<a.count {
        if a[i - 1] < a[i] {
            return false
        }
    }
    return true
}

func blit_reverse(_ a: UnsafeMutableBufferPointer<Int>) {
    blit_reverse_range(a)
}

func blit_ordered_pairs(_ a: UnsafeMutableBufferPointer<Int>) -> Int {
    if a.count < 2 {
        return 0
    }
    var count = 0
    for i in 1..<a.count {
        if a[i - 1] <= a[i] {
            count += 1
        }
    }
    return count
}

func blit_median3_idx(_ a: UnsafeMutableBufferPointer<Int>, _ i: Int, _ j: Int, _ k: Int) -> Int {
    let x = a[i]
    let y = a[j]
    let z = a[k]
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

func blit_quasimedian9(_ a: UnsafeMutableBufferPointer<Int>) -> Int {
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
    let m0 = blit_median3_idx(a, i0, i1, i2)
    let m1 = blit_median3_idx(a, i3, i4, i5)
    let m2 = blit_median3_idx(a, i6, i7, i8)
    return a[blit_median3_idx(a, m0, m1, m2)]
}

/// Rotate `a` so the prefix of length `left` moves after the suffix.
/// Prefer a swap-assisted block move; otherwise fall back to three reverses
/// (educational stand-in for trinity / bridge rotations).
func blit_rotate(_ a: UnsafeMutableBufferPointer<Int>, _ left: Int, _ swap: UnsafeMutableBufferPointer<Int>) {
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
            let moved = Array(a[left..<n])
            for i in 0..<moved.count {
                a[i] = moved[i]
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
        let moved = Array(a[0..<left])
        for i in 0..<moved.count {
            a[right + i] = moved[i]
        }
        for i in 0..<right {
            a[i] = swap[i]
        }
        return
    }

    blit_reverse_range(UnsafeMutableBufferPointer(rebasing: a[0..<left]))
    blit_reverse_range(UnsafeMutableBufferPointer(rebasing: a[left..<n]))
    blit_reverse_range(a)
}

/// Lower bound: first index `i` in `hay` with `hay[i] >= needle`.
func blit_lower_bound(_ hay: UnsafeMutableBufferPointer<Int>, _ needle: Int) -> Int {
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

func blit_merge_with_swap(
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

/// Merge two adjacent sorted runs `[0..left_len)` and `[left_len..left_len+right_len)`
/// by rotating around the left run's center until the pieces fit in `swap`.
func blit_rotate_merge_block(
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
        blit_merge_with_swap(a, left_len, swap)
        return
    }
    if left_len <= swap_cap {
        blit_merge_with_swap(a, left_len, swap)
        return
    }
    if right_len <= swap_cap {
        // Partial backward merge: right run fits in swap.
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
    let left = blit_lower_bound(UnsafeMutableBufferPointer(rebasing: a[left_len..<total]), center)
    let right = right_len - left

    // Layout: [ lblock | rblock | left | right ]
    if left > 0 {
        blit_rotate(
            UnsafeMutableBufferPointer(rebasing: a[lblock..<(lblock + rblock + left)]),
            rblock,
            swap
        )
        // Now: [ lblock | left | rblock | right ]
        blit_rotate_merge_block(a, lblock, left, swap)
        blit_rotate_merge_block(
            UnsafeMutableBufferPointer(rebasing: a[(lblock + left)..<total]),
            rblock,
            right,
            swap
        )
    } else if right > 0 {
        blit_rotate_merge_block(
            UnsafeMutableBufferPointer(rebasing: a[lblock..<total]),
            rblock,
            right,
            swap
        )
    }
}

func blit_rotate_mergesort(_ a: UnsafeMutableBufferPointer<Int>, _ swap: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    let block0 = max(min(BLIT_OUT, swap.count), 1)
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
            blit_rotate_merge_block(
                UnsafeMutableBufferPointer(rebasing: a[start..<end]),
                left_len,
                right_len,
                swap
            )
            start = end
        }
        if block > Int.max / 2 {
            break
        }
        block *= 2
        if block == 0 {
            break
        }
    }
}

/// Stable partition: keys `<= pivot` stay toward the front.
/// When the range exceeds the swap, recurse on halves and rotate the middle
/// so left parts gather contiguously (rotate quicksort's assembly step).
func blit_stable_partition(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ swap: UnsafeMutableBufferPointer<Int>,
    _ pivot: Int
) -> Int {
    let n = a.count
    let swap_cap = swap.count
    if n == 0 {
        return 0
    }
    if n > swap_cap {
        let h = n / 2
        let l = blit_stable_partition(UnsafeMutableBufferPointer(rebasing: a[0..<h]), swap, pivot)
        let r = blit_stable_partition(UnsafeMutableBufferPointer(rebasing: a[h..<n]), swap, pivot)
        // Middle band `a[l..h]` holds the right half of the left partition
        // (`> pivot`); length `h - l`. Right partition contributed `r` left keys
        // at `a[h..h+r]`. Rotate that band of length `(h - l) + r` by `h - l`.
        blit_rotate(UnsafeMutableBufferPointer(rebasing: a[l..<(h + r)]), h - l, swap)
        return l + r
    }

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

/// Like `blit_stable_partition`, but left keys are strictly less than `pivot`.
/// Used for the equal-key second sweep so ranges larger than the fixed swap
/// still stay within that buffer via half-recursion and rotate.
func blit_strict_partition(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ swap: UnsafeMutableBufferPointer<Int>,
    _ pivot: Int
) -> Int {
    let n = a.count
    let swap_cap = swap.count
    if n == 0 {
        return 0
    }
    if n > swap_cap {
        let h = n / 2
        let l = blit_strict_partition(UnsafeMutableBufferPointer(rebasing: a[0..<h]), swap, pivot)
        let r = blit_strict_partition(UnsafeMutableBufferPointer(rebasing: a[h..<n]), swap, pivot)
        blit_rotate(UnsafeMutableBufferPointer(rebasing: a[l..<(h + r)]), h - l, swap)
        return l + r
    }

    for i in 0..<n {
        swap[i] = a[i]
    }
    var left = 0
    for i in 0..<n {
        if swap[i] < pivot {
            left += 1
        }
    }
    var l = 0
    var r = left
    for i in 0..<n {
        let x = swap[i]
        if x < pivot {
            a[l] = x
            l += 1
        } else {
            a[r] = x
            r += 1
        }
    }
    return left
}

func blit_partition_sort(_ a: UnsafeMutableBufferPointer<Int>, _ swap: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    if n <= BLIT_OUT {
        insertion_sort(a)
        return
    }

    let pivot = blit_quasimedian9(a)
    let left = blit_stable_partition(a, swap, pivot)
    let right = n - left

    if right == 0 {
        // Second sweep: gather keys strictly less than pivot. When `n` exceeds
        // the fixed swap, recurse + rotate instead of copying the whole range.
        let lt = blit_strict_partition(a, swap, pivot)
        if lt > 1 {
            blit_partition_sort(UnsafeMutableBufferPointer(rebasing: a[0..<lt]), swap)
        }
        return
    }

    let unbalanced = (left > 0 && left < n / 16) || (right > 0 && right < n / 16)
    if unbalanced {
        if left > 1 {
            blit_rotate_mergesort(UnsafeMutableBufferPointer(rebasing: a[0..<left]), swap)
        }
        if right > 1 {
            blit_rotate_mergesort(UnsafeMutableBufferPointer(rebasing: a[left..<n]), swap)
        }
        return
    }

    if left > 1 {
        blit_partition_sort(UnsafeMutableBufferPointer(rebasing: a[0..<left]), swap)
    }
    if right > 1 {
        blit_partition_sort(UnsafeMutableBufferPointer(rebasing: a[left..<n]), swap)
    }
}

func blit_analyze(_ a: UnsafeMutableBufferPointer<Int>, _ swap: UnsafeMutableBufferPointer<Int>) -> Bool {
    let n = a.count
    if n <= 1 {
        return true
    }
    if blit_is_sorted(a) {
        return true
    }
    if blit_is_reverse_sorted(a) {
        blit_reverse(a)
        return true
    }

    // Four-segment presortedness (flux / blit analyzer stand-in): finish
    // mostly-ordered quarters with rotate mergesort, then fall through to
    // rotate quicksort for remaining disorder.
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
            if blit_ordered_pairs(UnsafeMutableBufferPointer(rebasing: a[lo..<hi])) * 2 > pairs {
                blit_rotate_mergesort(UnsafeMutableBufferPointer(rebasing: a[lo..<hi]), swap)
            }
        }
        if blit_is_sorted(a) {
            return true
        }
    }
    return false
}

func blit_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { blit_sort($0) }
}

func blit_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    if n <= BLIT_OUT {
        insertion_sort(a)
        return
    }
    let swap_len = min(BLIT_SWAP, n)
    var swap = Array(repeating: 0, count: swap_len)
    let done = swap.withUnsafeMutableBufferPointer { swapBuf -> Bool in
        blit_analyze(a, swapBuf)
    }
    if done {
        return
    }
    swap.withUnsafeMutableBufferPointer { swapBuf in
        blit_partition_sort(a, swapBuf)
    }
}
