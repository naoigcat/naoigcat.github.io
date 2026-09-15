func natural_merge_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { natural_merge_sort($0) }
}

func natural_merge_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    while true {
        var runs = [(Int, Int)]()
        var i = 0
        while i < n {
            let start = i
            i += 1
            while i < n && a[i - 1] <= a[i] {
                i += 1
            }
            runs.append((start, i))
        }
        if runs.count <= 1 {
            return
        }
        var k = 0
        while k + 1 < runs.count {
            let (lo, mid) = runs[k]
            let (_, hi) = runs[k + 1]
            var merged = [Int]()
            merged.reserveCapacity(hi - lo)
            var l = lo
            var r = mid
            while l < mid && r < hi {
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
            while r < hi {
                merged.append(a[r])
                r += 1
            }
            for j in 0..<merged.count {
                a[lo + j] = merged[j]
            }
            k += 2
        }
    }
}
