func library_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { library_sort($0) }
}

func library_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    var shelf = [Int]()
    shelf.reserveCapacity(a.count)
    for i in 0..<a.count {
        let value = a[i]
        var lo = 0
        var hi = shelf.count
        while lo < hi {
            let mid = lo + (hi - lo) / 2
            if shelf[mid] < value {
                lo = mid + 1
            } else if shelf[mid] > value {
                hi = mid
            } else {
                lo = mid
                break
            }
        }
        shelf.insert(value, at: lo)
    }
    for i in 0..<a.count {
        a[i] = shelf[i]
    }
}
