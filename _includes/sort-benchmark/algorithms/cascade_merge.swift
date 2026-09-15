func wmerge(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ i: Int,
    _ m: Int,
    _ j: Int,
    _ n: Int,
    _ w: Int
) {
    var i = i
    var j = j
    var w = w
    while i < m && j < n {
        if a[i] <= a[j] {
            a.swapAt(w, i)
            w += 1
            i += 1
        } else {
            a.swapAt(w, j)
            w += 1
            j += 1
        }
    }
    while i < m {
        a.swapAt(w, i)
        w += 1
        i += 1
    }
    while j < n {
        a.swapAt(w, j)
        w += 1
        j += 1
    }
}

func wsort(_ a: UnsafeMutableBufferPointer<Int>, _ l: Int, _ u: Int, _ w: Int) {
    if u - l > 1 {
        let m = l + (u - l) / 2
        imsort_range(a, l, m)
        imsort_range(a, m, u)
        wmerge(a, l, m, m, u, w)
    } else {
        var l = l
        var w = w
        while l < u {
            a.swapAt(l, w)
            l += 1
            w += 1
        }
    }
}

func imsort_range(_ a: UnsafeMutableBufferPointer<Int>, _ l: Int, _ u: Int) {
    if u - l <= 1 {
        return
    }
    let m = l + (u - l) / 2
    var w = l + u - m
    wsort(a, l, m, w)
    while w - l > 2 {
        let n = w
        w = l + (n - l + 1) / 2
        wsort(a, w, n, l)
        wmerge(a, l, l + n - w, n, u, w)
    }
    var n = w
    while n > l {
        var m_idx = n
        while m_idx < u && a[m_idx] < a[m_idx - 1] {
            a.swapAt(m_idx, m_idx - 1)
            m_idx += 1
        }
        n -= 1
    }
}

func cascade_merge_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { cascade_merge_sort($0) }
}

func cascade_merge_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count <= 1 {
        return
    }
    imsort_range(a, 0, a.count)
}
