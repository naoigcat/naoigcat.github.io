func partition(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ hi: Int) -> Int {
    partition_at(a, lo, hi, lo + (hi - lo) / 2)
}
