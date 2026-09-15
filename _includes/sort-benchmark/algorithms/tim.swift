func tim_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { tim_sort($0) }
}

func tim_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let MIN_RUN = 32
    let n = a.count
    var runs = [(Int, Int)]()
    var i = 0
    while i < n {
        let start = i
        i += 1
        if i < n && a[i - 1] > a[i] {
            while i < n && a[i - 1] > a[i] {
                i += 1
            }
            var lo = start
            var hi = i - 1
            while lo < hi {
                a.swapAt(lo, hi)
                lo += 1
                hi -= 1
            }
        } else {
            while i < n && a[i - 1] <= a[i] {
                i += 1
            }
        }
        let end = max(min(start + MIN_RUN, n), i)
        insertion_sort(UnsafeMutableBufferPointer(rebasing: a[start..<end]))
        runs.append((start, end))
        i = end
    }
    while runs.count > 1 {
        var next = [(Int, Int)]()
        var idx = 0
        while idx < runs.count {
            if idx + 1 >= runs.count {
                next.append(runs[idx])
                break
            }
            let (lo, mid) = runs[idx]
            let (_, hi) = runs[idx + 1]
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
            next.append((lo, hi))
            idx += 2
        }
        runs = next
    }
}
