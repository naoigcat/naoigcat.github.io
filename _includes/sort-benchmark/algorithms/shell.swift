func shell_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { shell_sort($0) }
}

func shell_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    var gap = a.count / 2
    while gap > 0 {
        for i in gap..<a.count {
            let x = a[i]
            var j = i
            while j >= gap && a[j - gap] > x {
                a[j] = a[j - gap]
                j -= gap
            }
            a[j] = x
        }
        gap /= 2
    }
}
