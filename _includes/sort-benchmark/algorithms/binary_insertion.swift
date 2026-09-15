func binary_insertion_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { binary_insertion_sort($0) }
}

func binary_insertion_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count < 2 {
        return
    }
    for i in 1..<a.count {
        let key = a[i]
        var lo = 0
        var hi = i
        while lo < hi {
            let mid = lo + (hi - lo) / 2
            if a[mid] > key {
                hi = mid
            } else {
                lo = mid + 1
            }
        }
        var j = i
        while j > lo {
            a[j] = a[j - 1]
            j -= 1
        }
        a[lo] = key
    }
}
