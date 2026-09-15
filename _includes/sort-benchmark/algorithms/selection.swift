func selection_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { selection_sort($0) }
}

func selection_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    for i in 0..<a.count {
        var min = i
        for j in (i + 1)..<a.count {
            if a[j] < a[min] {
                min = j
            }
        }
        a.swapAt(i, min)
    }
}
