func brick_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { brick_sort($0) }
}

func brick_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    var sorted = false
    while !sorted {
        sorted = true
        var i = 1
        while i < a.count {
            if a[i - 1] > a[i] {
                a.swapAt(i - 1, i)
                sorted = false
            }
            i += 2
        }
        i = 2
        while i < a.count {
            if a[i - 1] > a[i] {
                a.swapAt(i - 1, i)
                sorted = false
            }
            i += 2
        }
    }
}
