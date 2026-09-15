func sift_down(_ a: UnsafeMutableBufferPointer<Int>, _ root: Int, _ end: Int) {
    var root = root
    while true {
        let child = root * 2 + 1
        if child > end {
            break
        }
        var swap_idx = child
        if child < end && a[child] < a[child + 1] {
            swap_idx = child + 1
        }
        if a[root] >= a[swap_idx] {
            break
        }
        a.swapAt(root, swap_idx)
        root = swap_idx
    }
}

func heap_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { heap_sort($0) }
}

func heap_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count <= 1 {
        return
    }
    for start in (0..<(a.count / 2)).reversed() {
        sift_down(a, start, a.count - 1)
    }
    for end in (1..<a.count).reversed() {
        a.swapAt(0, end)
        sift_down(a, 0, end - 1)
    }
}
