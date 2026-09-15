func comb_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { comb_sort($0) }
}

func comb_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    var gap = a.count
    var swapped = true
    while gap > 1 || swapped {
        gap = max(gap * 10 / 13, 1)
        swapped = false
        let limit = max(a.count - gap, 0)
        for i in 0..<limit {
            if a[i] > a[i + gap] {
                a.swapAt(i, i + gap)
                swapped = true
            }
        }
    }
}
