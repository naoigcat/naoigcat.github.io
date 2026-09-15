func exchange_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { exchange_sort($0) }
}

func exchange_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    for i in 0..<a.count {
        for j in (i + 1)..<a.count {
            if a[j] < a[i] {
                a.swapAt(i, j)
            }
        }
    }
}
