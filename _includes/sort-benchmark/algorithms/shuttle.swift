func shuttle_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { shuttle_sort($0) }
}

func shuttle_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    insertion_sort(a)
}
