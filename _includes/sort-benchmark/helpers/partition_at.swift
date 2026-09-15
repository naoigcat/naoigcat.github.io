func partition_at(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ hi: Int, _ pivot_idx: Int) -> Int {
    a.swapAt(pivot_idx, hi)
    let pivot = a[hi]
    var i = lo
    for j in lo..<hi {
        if a[j] < pivot {
            a.swapAt(i, j)
            i += 1
        }
    }
    a.swapAt(i, hi)
    return i
}
