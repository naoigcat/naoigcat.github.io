private func franceschini_branch_factor(_ len: Int) -> Int {
    if len <= 2 {
        return 2
    }
    var d = 2
    while d * d * d * d < len {
        d += 1
        if d > 64 {
            break
        }
    }
    return max(d, 2)
}

private func franceschini_child(_ parent: Int, _ which: Int, _ d: Int) -> Int {
    parent * d + 1 + which
}

private func franceschini_sift_down(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ root: Int,
    _ end: Int,
    _ d: Int
) {
    var root = root
    while true {
        let first = franceschini_child(root, 0, d)
        if first > end {
            break
        }
        var best = first
        let last = min(first + d - 1, end)
        if first + 1 <= last {
            for child in (first + 1)...last {
                if a[child] > a[best] {
                    best = child
                }
            }
        }
        if a[root] >= a[best] {
            break
        }
        a.swapAt(root, best)
        root = best
    }
}

private func franceschini_dary_heap_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    let d = franceschini_branch_factor(n)
    let last_parent = (n - 2) / d
    for start in stride(from: last_parent, through: 0, by: -1) {
        franceschini_sift_down(a, start, n - 1, d)
    }
    for end in stride(from: n - 1, through: 1, by: -1) {
        a.swapAt(0, end)
        if end > 1 {
            franceschini_sift_down(a, 0, end - 1, d)
        }
    }
}

private func franceschini_insertion_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    for i in 1..<a.count {
        let key = a[i]
        var j = i
        while j > 0 && a[j - 1] > key {
            a[j] = a[j - 1]
            j -= 1
        }
        a[j] = key
    }
}

private func franceschini_partition_at(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ left: Int,
    _ right: Int,
    _ pivot_index: Int
) -> Int {
    a.swapAt(pivot_index, right)
    let pivot = a[right]
    var store = left
    for i in left..<right {
        if a[i] < pivot {
            a.swapAt(store, i)
            store += 1
        }
    }
    a.swapAt(store, right)
    return store
}

private func franceschini_quickselect(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ left: Int,
    _ right: Int,
    _ k: Int
) {
    var left = left
    var right = right
    while left < right {
        let mid = left + (right - left) / 2
        if a[right] < a[left] {
            a.swapAt(left, right)
        }
        if a[mid] < a[left] {
            a.swapAt(left, mid)
        }
        if a[right] < a[mid] {
            a.swapAt(mid, right)
        }
        let pivot_index = franceschini_partition_at(a, left, right, mid)
        if k == pivot_index {
            return
        } else if k < pivot_index {
            if pivot_index == 0 {
                return
            }
            right = pivot_index - 1
        } else {
            left = pivot_index + 1
        }
    }
}

private func franceschini_sort_with_buffer(
    _ active: UnsafeMutableBufferPointer<Int>,
    _ buffer: UnsafeMutableBufferPointer<Int>
) {
    let m = active.count
    if m == 0 {
        return
    }
    for i in 0..<m {
        let t = active[i]; active[i] = buffer[i]; buffer[i] = t
    }
    if m <= 32 {
        franceschini_insertion_sort(UnsafeMutableBufferPointer(rebasing: buffer[0..<m]))
    } else {
        franceschini_dary_heap_sort(UnsafeMutableBufferPointer(rebasing: buffer[0..<m]))
    }
    for i in 0..<m {
        let t = active[i]; active[i] = buffer[i]; buffer[i] = t
    }
}

private func franceschini_rec(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    if n <= 64 {
        if n <= 32 {
            franceschini_insertion_sort(a)
        } else {
            franceschini_dary_heap_sort(a)
        }
        return
    }

    let rank = n / 4
    franceschini_quickselect(a, 0, n - 1, rank)
    let pivot = a[rank]

    var split = 0
    for i in 0..<n {
        if a[i] < pivot {
            a.swapAt(split, i)
            split += 1
        }
    }

    if split == 0 || split > n - split {
        franceschini_dary_heap_sort(a)
        return
    }

    franceschini_sort_with_buffer(
        UnsafeMutableBufferPointer(rebasing: a[0..<split]),
        UnsafeMutableBufferPointer(rebasing: a[split..<n])
    )

    franceschini_rec(UnsafeMutableBufferPointer(rebasing: a[split..<n]))
}

func franceschini_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { franceschini_sort($0) }
}

func franceschini_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    franceschini_rec(a)
}
