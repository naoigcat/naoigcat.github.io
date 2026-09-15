func insertion_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { insertion_sort($0) }
}

func insertion_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count < 2 {
        return
    }
    for i in 1..<a.count {
        var j = i
        while j > 0 && a[j - 1] > a[j] {
            a.swapAt(j - 1, j)
            j -= 1
        }
    }
}
