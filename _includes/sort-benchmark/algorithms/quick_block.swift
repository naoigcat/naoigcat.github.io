fileprivate let BLOCK_SIZE = 128
fileprivate let INSERTION_THRESHOLD = 16

/// Branch-light Hoare-style partition used by BlockQuicksort (Edelkamp & Weiß).
/// Returns the final index of the pivot.
fileprivate func quick_block_partition(_ a: UnsafeMutableBufferPointer<Int>, _ begin: Int, _ end: Int) -> Int {
    // end is exclusive; pivot starts at midpoint of [begin, end).
    var begin = begin
    let mid = begin + (end - begin) / 2
    a.swapAt(mid, end - 1)
    let pivot = a[end - 1]
    var last = end - 2

    var index_l = [Int](repeating: 0, count: BLOCK_SIZE)
    var index_r = [Int](repeating: 0, count: BLOCK_SIZE)
    var num_left = 0
    var num_right = 0
    var start_left = 0
    var start_right = 0

    while begin <= last && last - begin + 1 > 2 * BLOCK_SIZE {
        if num_left == 0 {
            start_left = 0
            for j in 0..<BLOCK_SIZE {
                index_l[num_left] = j
                // left buffer: elements >= pivot (need to move right)
                num_left += a[begin + j] < pivot ? 0 : 1
            }
        }
        if num_right == 0 {
            start_right = 0
            for j in 0..<BLOCK_SIZE {
                index_r[num_right] = j
                // right buffer: elements <= pivot (need to move left)
                num_right += pivot < a[last - j] ? 0 : 1
            }
        }

        let num = min(num_left, num_right)
        for j in 0..<num {
            let li = begin + index_l[start_left + j]
            let ri = last - index_r[start_right + j]
            a.swapAt(li, ri)
        }
        num_left -= num
        num_right -= num
        start_left += num
        start_right += num
        if num_left == 0 {
            begin += BLOCK_SIZE
        }
        if num_right == 0 {
            last -= BLOCK_SIZE
        }
    }

    // Final (partial) scan of the remaining ≤ 2B elements.
    let shift_l: Int
    let shift_r: Int
    if num_right == 0 && num_left == 0 {
        let len = last - begin + 1
        shift_l = len / 2
        shift_r = len - shift_l
        start_left = 0
        start_right = 0
        for j in 0..<shift_l {
            index_l[num_left] = j
            num_left += a[begin + j] < pivot ? 0 : 1
            index_r[num_right] = j
            num_right += pivot < a[last - j] ? 0 : 1
        }
        if shift_l < shift_r {
            index_r[num_right] = shift_r - 1
            num_right += pivot < a[last - (shift_r - 1)] ? 0 : 1
        }
    } else if num_right != 0 {
        shift_l = last - begin + 1 - BLOCK_SIZE
        shift_r = BLOCK_SIZE
        start_left = 0
        for j in 0..<shift_l {
            index_l[num_left] = j
            num_left += a[begin + j] < pivot ? 0 : 1
        }
    } else {
        shift_l = BLOCK_SIZE
        shift_r = last - begin + 1 - BLOCK_SIZE
        start_right = 0
        for j in 0..<shift_r {
            index_r[num_right] = j
            num_right += pivot < a[last - j] ? 0 : 1
        }
    }

    let num = min(num_left, num_right)
    for j in 0..<num {
        let li = begin + index_l[start_left + j]
        let ri = last - index_r[start_right + j]
        a.swapAt(li, ri)
    }
    num_left -= num
    num_right -= num
    start_left += num
    start_right += num
    if num_left == 0 {
        begin += shift_l
    }
    if num_right == 0 {
        last = last &- shift_r
    }

    // Drain leftovers still recorded in one buffer.
    // `upper` is signed because the reference finish may leave it at -1.
    if num_left != 0 {
        var lower_i = start_left + num_left - 1
        var upper = last - begin
        while lower_i >= start_left && index_l[lower_i] == upper {
            upper -= 1
            lower_i -= 1
        }
        while lower_i >= start_left {
            a.swapAt(begin + upper, begin + index_l[lower_i])
            upper -= 1
            lower_i -= 1
        }
        let pivot_pos = begin + upper + 1
        a.swapAt(end - 1, pivot_pos)
        return pivot_pos
    } else if num_right != 0 {
        var lower_i = start_right + num_right - 1
        var upper = last - begin
        while lower_i >= start_right && index_r[lower_i] == upper {
            upper -= 1
            lower_i -= 1
        }
        while lower_i >= start_right {
            a.swapAt(last - upper, last - index_r[lower_i])
            upper -= 1
            lower_i -= 1
        }
        let pivot_pos = last - upper
        a.swapAt(end - 1, pivot_pos)
        return pivot_pos
    } else {
        a.swapAt(end - 1, begin)
        return begin
    }
}

fileprivate func quick_block_sort_range(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ hi: Int) {
    if hi <= lo {
        return
    }
    if hi - lo < INSERTION_THRESHOLD {
        insertion_sort(UnsafeMutableBufferPointer(rebasing: a[lo..<(hi + 1)]))
        return
    }
    let pivot_pos = quick_block_partition(a, lo, hi + 1)
    if pivot_pos > lo {
        quick_block_sort_range(a, lo, pivot_pos - 1)
    }
    if pivot_pos < hi {
        quick_block_sort_range(a, pivot_pos + 1, hi)
    }
}

func quick_block_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { quick_block_sort($0) }
}

func quick_block_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count > 0 {
        let hi = a.count - 1
        quick_block_sort_range(a, 0, hi)
    }
}
