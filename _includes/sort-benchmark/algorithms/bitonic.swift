func compare_exchange(_ a: UnsafeMutableBufferPointer<Int>, _ i: Int, _ j: Int, _ dir_up: Bool) {
    let swap: Bool
    if dir_up {
        swap = a[i] > a[j]
    } else {
        swap = a[i] < a[j]
    }
    if swap {
        a.swapAt(i, j)
    }
}

func bitonic_merge(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ cnt: Int, _ dir_up: Bool) {
    if cnt <= 1 {
        return
    }
    let k = cnt / 2
    for i in lo..<(lo + k) {
        compare_exchange(a, i, i + k, dir_up)
    }
    bitonic_merge(a, lo, k, dir_up)
    bitonic_merge(a, lo + k, k, dir_up)
}

func bitonic_sort_range(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ cnt: Int, _ dir_up: Bool) {
    if cnt <= 1 {
        return
    }
    let k = cnt / 2
    bitonic_sort_range(a, lo, k, true)
    bitonic_sort_range(a, lo + k, k, false)
    bitonic_merge(a, lo, cnt, dir_up)
}

func bitonic_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { bitonic_sort($0) }
}

func bitonic_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    if n > 0 && (n & (n - 1)) == 0 {
        bitonic_sort_range(a, 0, n, true)
        return
    }
    // Classic bitonic sort assumes a power-of-two length; pad for other sizes.
    var k = 1
    while k < n {
        if k > Int.max / 2 {
            k = Int.max
            break
        }
        k *= 2
    }
    var buf = Array(repeating: Int.max, count: k)
    for i in 0..<n {
        buf[i] = a[i]
    }
    buf.withUnsafeMutableBufferPointer { bitonic_sort_range($0, 0, k, true) }
    for i in 0..<n {
        a[i] = buf[i]
    }
}
