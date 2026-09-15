fileprivate func odd_even_merge(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ n: Int, _ r: Int) {
    let m = r * 2
    if m < n {
        odd_even_merge(a, lo, n, m)
        odd_even_merge(a, lo + r, n, m)
        var i = lo + r
        while i + r < lo + n {
            if a[i] > a[i + r] {
                a.swapAt(i, i + r)
            }
            i += m
        }
    } else if lo + r < a.count {
        if a[lo] > a[lo + r] {
            a.swapAt(lo, lo + r)
        }
    }
}

fileprivate func next_power_of_two(_ n: UInt) -> UInt {
    if n <= 1 {
        return 1
    }
    var v = n - 1
    v |= v >> 1
    v |= v >> 2
    v |= v >> 4
    v |= v >> 8
    v |= v >> 16
    v |= v >> 32
    return v + 1
}

fileprivate func odd_even_merge_sort_range(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ n: Int) {
    if n <= 1 {
        return
    }
    let half = n / 2
    odd_even_merge_sort_range(a, lo, half)
    odd_even_merge_sort_range(a, lo + half, half)
    odd_even_merge(a, lo, n, 1)
}

func odd_even_merge_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { odd_even_merge_sort($0) }
}

func odd_even_merge_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    if n > 0 && (n & (n - 1)) == 0 {
        odd_even_merge_sort_range(a, 0, n)
        return
    }
    // Classic odd-even mergesort assumes a power-of-two length; pad for other sizes.
    let k = Int(next_power_of_two(UInt(n)))
    var buf = [Int](repeating: Int.max, count: k)
    for i in 0..<n {
        buf[i] = a[i]
    }
    buf.withUnsafeMutableBufferPointer { bufPtr in
        odd_even_merge_sort_range(bufPtr, 0, k)
    }
    for i in 0..<n {
        a[i] = buf[i]
    }
}
