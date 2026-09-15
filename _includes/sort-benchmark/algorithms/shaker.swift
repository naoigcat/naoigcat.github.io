func shaker_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { shaker_sort($0) }
}

func shaker_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count <= 1 {
        return
    }
    var left = 0
    var right = a.count - 1
    while left < right {
        var swapped = false
        for i in left..<right {
            if a[i] > a[i + 1] {
                a.swapAt(i, i + 1)
                swapped = true
            }
        }
        if !swapped {
            break
        }
        right -= 1
        swapped = false
        for i in stride(from: right, through: left + 1, by: -1) {
            if a[i - 1] > a[i] {
                a.swapAt(i - 1, i)
                swapped = true
            }
        }
        if !swapped {
            break
        }
        left += 1
    }
}
