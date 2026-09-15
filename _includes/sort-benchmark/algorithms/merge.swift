func merge_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { merge_sort($0) }
}

func merge_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    let mid = n / 2
    merge_sort(UnsafeMutableBufferPointer(rebasing: a[0..<mid]))
    merge_sort(UnsafeMutableBufferPointer(rebasing: a[mid..<n]))
    var merged = [Int]()
    merged.reserveCapacity(n)
    var l = 0
    var r = mid
    while l < mid && r < n {
        if a[l] <= a[r] {
            merged.append(a[l])
            l += 1
        } else {
            merged.append(a[r])
            r += 1
        }
    }
    while l < mid {
        merged.append(a[l])
        l += 1
    }
    while r < n {
        merged.append(a[r])
        r += 1
    }
    for i in 0..<n {
        a[i] = merged[i]
    }
}
