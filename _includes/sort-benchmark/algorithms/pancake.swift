fileprivate func flip_prefix(_ a: UnsafeMutableBufferPointer<Int>, _ end: Int) {
    var lo = 0
    var hi = end
    while lo < hi {
        a.swapAt(lo, hi)
        lo += 1
        hi -= 1
    }
}

func pancake_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { pancake_sort($0) }
}

func pancake_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n < 2 {
        return
    }
    for size in (2...n).reversed() {
        var max_idx = 0
        for i in 1..<size {
            if a[i] > a[max_idx] {
                max_idx = i
            }
        }
        if max_idx != size - 1 {
            if max_idx != 0 {
                flip_prefix(a, max_idx)
            }
            flip_prefix(a, size - 1)
        }
    }
}
