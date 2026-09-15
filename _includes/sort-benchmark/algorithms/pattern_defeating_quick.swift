fileprivate let INSERTION_SORT_THRESHOLD = 24
fileprivate let NINTHER_THRESHOLD = 128
fileprivate let PARTIAL_INSERTION_SORT_LIMIT = 8

fileprivate func floor_log2(_ n: Int) -> Int {
    Int.bitWidth - n.leadingZeroBitCount - 1
}

fileprivate func sort2(_ a: UnsafeMutableBufferPointer<Int>, _ i: Int, _ j: Int) {
    if a[j] < a[i] {
        a.swapAt(i, j)
    }
}

fileprivate func sort3(_ a: UnsafeMutableBufferPointer<Int>, _ i: Int, _ j: Int, _ k: Int) {
    sort2(a, i, j)
    sort2(a, j, k)
    sort2(a, i, j)
}

fileprivate func partial_insertion_sort_range(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ hi: Int) -> Bool {
    if hi <= lo {
        return true
    }
    var limit = 0
    for i in (lo + 1)...hi {
        if a[i] < a[i - 1] {
            let tmp = a[i]
            var j = i
            while true {
                a[j] = a[j - 1]
                j -= 1
                if j == lo || !(tmp < a[j - 1]) {
                    break
                }
            }
            a[j] = tmp
            limit += i - j
            if limit > PARTIAL_INSERTION_SORT_LIMIT {
                return false
            }
        }
    }
    return true
}

/// Partition `[lo, hi]` around pivot at `lo`. Equals go to the right.
/// Returns `(pivot_pos, already_partitioned)`.
fileprivate func partition_right_range(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ hi: Int) -> (Int, Bool) {
    let pivot = a[lo]
    var first = lo
    var last = hi + 1

    while true {
        first += 1
        if !(a[first] < pivot) {
            break
        }
    }

    if first - 1 == lo {
        while true {
            if first >= last {
                break
            }
            last -= 1
            if a[last] < pivot {
                break
            }
        }
    } else {
        while true {
            last -= 1
            if a[last] < pivot {
                break
            }
        }
    }

    let already_partitioned = first >= last
    while first < last {
        a.swapAt(first, last)
        while true {
            first += 1
            if !(a[first] < pivot) {
                break
            }
        }
        while true {
            last -= 1
            if a[last] < pivot {
                break
            }
        }
    }

    let pivot_pos = first - 1
    a[lo] = a[pivot_pos]
    a[pivot_pos] = pivot
    return (pivot_pos, already_partitioned)
}

/// Partition `[lo, hi]` around pivot at `lo`. Equals go to the left.
fileprivate func partition_left_range(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ hi: Int) -> Int {
    let pivot = a[lo]
    var first = lo
    var last = hi + 1

    while true {
        last -= 1
        if !(pivot < a[last]) {
            break
        }
    }

    if last + 1 == hi + 1 {
        while true {
            if first >= last {
                break
            }
            first += 1
            if pivot < a[first] {
                break
            }
        }
    } else {
        while true {
            first += 1
            if pivot < a[first] {
                break
            }
        }
    }

    while first < last {
        a.swapAt(first, last)
        while true {
            last -= 1
            if !(pivot < a[last]) {
                break
            }
        }
        while true {
            first += 1
            if pivot < a[first] {
                break
            }
        }
    }

    a[lo] = a[last]
    a[last] = pivot
    return last
}

fileprivate func pattern_defeating_quick_sort_loop(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ lo: Int,
    _ hi: Int,
    _ bad_allowed: Int,
    _ leftmost: Bool
) {
    var lo = lo
    var bad_allowed = bad_allowed
    var leftmost = leftmost
    while lo <= hi {
        let size = hi - lo + 1
        if size < INSERTION_SORT_THRESHOLD {
            insertion_sort(UnsafeMutableBufferPointer(rebasing: a[lo..<(hi + 1)]))
            return
        }

        let s2 = size / 2
        if size > NINTHER_THRESHOLD {
            sort3(a, lo, lo + s2, hi)
            sort3(a, lo + 1, lo + (s2 - 1), hi - 1)
            sort3(a, lo + 2, lo + (s2 + 1), hi - 2)
            sort3(a, lo + (s2 - 1), lo + s2, lo + (s2 + 1))
            a.swapAt(lo, lo + s2)
        } else {
            sort3(a, lo + s2, lo, hi)
        }

        if !leftmost && !(a[lo - 1] < a[lo]) {
            lo = partition_left_range(a, lo, hi) + 1
            if lo > hi {
                return
            }
            continue
        }

        let (pivot_pos, already_partitioned) = partition_right_range(a, lo, hi)
        let l_size = pivot_pos - lo
        let r_size = hi - pivot_pos
        let highly_unbalanced = l_size < size / 8 || r_size < size / 8

        if highly_unbalanced {
            if bad_allowed == 0 {
                heap_sort(UnsafeMutableBufferPointer(rebasing: a[lo..<(hi + 1)]))
                return
            }
            bad_allowed -= 1

            if l_size >= INSERTION_SORT_THRESHOLD {
                a.swapAt(lo, lo + l_size / 4)
                a.swapAt(pivot_pos - 1, pivot_pos - l_size / 4)
                if l_size > NINTHER_THRESHOLD {
                    a.swapAt(lo + 1, lo + (l_size / 4 + 1))
                    a.swapAt(lo + 2, lo + (l_size / 4 + 2))
                    a.swapAt(pivot_pos - 2, pivot_pos - (l_size / 4 + 1))
                    a.swapAt(pivot_pos - 3, pivot_pos - (l_size / 4 + 2))
                }
            }

            if r_size >= INSERTION_SORT_THRESHOLD {
                a.swapAt(pivot_pos + 1, pivot_pos + (1 + r_size / 4))
                a.swapAt(hi, hi + 1 - r_size / 4)
                if r_size > NINTHER_THRESHOLD {
                    a.swapAt(pivot_pos + 2, pivot_pos + (2 + r_size / 4))
                    a.swapAt(pivot_pos + 3, pivot_pos + (3 + r_size / 4))
                    a.swapAt(hi - 1, hi - (r_size / 4))
                    a.swapAt(hi - 2, hi - (1 + r_size / 4))
                }
            }
        } else if already_partitioned
            && (pivot_pos == lo || partial_insertion_sort_range(a, lo, pivot_pos - 1))
            && (pivot_pos >= hi || partial_insertion_sort_range(a, pivot_pos + 1, hi))
        {
            return
        }

        if pivot_pos > lo {
            pattern_defeating_quick_sort_loop(a, lo, pivot_pos - 1, bad_allowed, leftmost)
        }
        lo = pivot_pos + 1
        leftmost = false
        if lo > hi {
            return
        }
    }
}

func pattern_defeating_quick_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { pattern_defeating_quick_sort($0) }
}

func pattern_defeating_quick_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count <= 1 {
        return
    }
    let bad_allowed = floor_log2(a.count)
    pattern_defeating_quick_sort_loop(a, 0, a.count - 1, bad_allowed, true)
}
