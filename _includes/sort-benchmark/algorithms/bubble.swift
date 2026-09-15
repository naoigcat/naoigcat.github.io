func bubble_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { bubble_sort($0) }
}

func bubble_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count <= 1 {
        return
    }

    var last = a.count - 1

    while last > 0 {
        var new_last = 0

        for i in 0..<last {
            if a[i] > a[i + 1] {
                a.swapAt(i, i + 1)
                new_last = i
            }
        }

        last = new_last
    }
}
