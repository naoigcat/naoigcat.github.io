/// Sort four elements with a small sorting network (equals keep order via `>`).
fileprivate func quad_swap4(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ i0: Int,
    _ i1: Int,
    _ i2: Int,
    _ i3: Int
) {
    if a[i0] > a[i1] {
        a.swapAt(i0, i1)
    }
    if a[i2] > a[i3] {
        a.swapAt(i2, i3)
    }
    if a[i0] > a[i2] {
        a.swapAt(i0, i2)
    }
    if a[i1] > a[i3] {
        a.swapAt(i1, i3)
    }
    if a[i1] > a[i2] {
        a.swapAt(i1, i2)
    }
}

fileprivate func quad_is_sorted(_ a: UnsafeMutableBufferPointer<Int>) -> Bool {
    for i in 1..<a.count {
        if a[i - 1] > a[i] {
            return false
        }
    }
    return true
}

fileprivate func quad_is_reverse_sorted(_ a: UnsafeMutableBufferPointer<Int>) -> Bool {
    for i in 1..<a.count {
        if a[i - 1] < a[i] {
            return false
        }
    }
    return true
}

fileprivate func quad_reverse(_ a: UnsafeMutableBufferPointer<Int>) {
    var lo = 0
    var hi = a.count
    while lo + 1 < hi {
        hi -= 1
        a.swapAt(lo, hi)
        lo += 1
    }
}

/// Stable two-way merge from `src[lo..<mid)` and `src[mid..<hi)` into `dst[lo..<hi)`.
fileprivate func quad_merge_two(
    _ src: UnsafeMutableBufferPointer<Int>,
    _ dst: UnsafeMutableBufferPointer<Int>,
    _ lo: Int,
    _ mid: Int,
    _ hi: Int
) {
    var i = lo
    var j = mid
    var k = lo
    while i < mid && j < hi {
        if src[i] <= src[j] {
            dst[k] = src[i]
            i += 1
        } else {
            dst[k] = src[j]
            j += 1
        }
        k += 1
    }
    while i < mid {
        dst[k] = src[i]
        i += 1
        k += 1
    }
    while j < hi {
        dst[k] = src[j]
        j += 1
        k += 1
    }
}

/// True when four consecutive sorted blocks of length `block` are already ordered
/// across boundaries (skipping the merge is safe).
fileprivate func quad_blocks_ordered(_ a: UnsafeMutableBufferPointer<Int>, _ start: Int, _ block: Int) -> Bool {
    a[start + block - 1] <= a[start + block]
        && a[start + block * 2 - 1] <= a[start + block * 2]
        && a[start + block * 3 - 1] <= a[start + block * 3]
}

/// Ping-pong quad merge: two pairwise merges into swap, then one merge back into `a`.
fileprivate func quad_merge_four(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ swap: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ block: Int
) {
    let mid1 = start + block
    let mid2 = start + block * 2
    let mid3 = start + block * 3
    let end = start + block * 4
    if quad_blocks_ordered(a, start, block) {
        return
    }
    quad_merge_two(a, swap, start, mid1, mid2)
    quad_merge_two(a, swap, mid2, mid3, end)
    quad_merge_two(swap, a, start, mid2, end)
}

/// Binary bottom-up merge for a partial span that is not a full group of four blocks.
fileprivate func quad_merge_remainder(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ swap: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ n: Int,
    _ block: Int
) {
    var width = block
    while start + width < n {
        var lo = start
        while lo + width < n {
            let mid = lo + width
            let hi = min(lo + width * 2, n)
            if a[mid - 1] > a[mid] {
                quad_merge_two(a, swap, lo, mid, hi)
                for i in lo..<hi {
                    a[i] = swap[i]
                }
            }
            lo = hi
        }
        width *= 2
    }
}

func quad_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { quad_sort($0) }
}

func quad_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    if quad_is_sorted(a) {
        return
    }
    if quad_is_reverse_sorted(a) {
        quad_reverse(a)
        return
    }

    // Analyzer / quad-swap: leave sorted blocks of 4 (educational stand-in for 8).
    var i = 0
    while i + 4 <= n {
        quad_swap4(a, i, i + 1, i + 2, i + 3)
        i += 4
    }
    if i < n {
        for j in (i + 1)..<n {
            let key = a[j]
            var k = j
            while k > i && a[k - 1] > key {
                a[k] = a[k - 1]
                k -= 1
            }
            a[k] = key
        }
    }

    var swapStorage = [Int](repeating: 0, count: n)
    swapStorage.withUnsafeMutableBufferPointer { swap in
        var block = 4
        while block < n {
            let stride = block * 4
            var start = 0
            while start < n {
                let rem = n - start
                if rem <= block {
                    break
                }
                if rem >= stride {
                    quad_merge_four(a, swap, start, block)
                    start += stride
                } else {
                    quad_merge_remainder(a, swap, start, n, block)
                    break
                }
            }
            block *= 4
        }
    }
}
