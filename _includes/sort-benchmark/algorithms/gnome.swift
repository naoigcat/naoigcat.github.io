func gnome_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { gnome_sort($0) }
}

func gnome_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    var i = 1
    while i < a.count {
        if i == 0 || a[i - 1] <= a[i] {
            i += 1
        } else {
            a.swapAt(i - 1, i)
            i -= 1
        }
    }
}
