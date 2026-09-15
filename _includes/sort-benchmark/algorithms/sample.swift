func sample_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { sample_sort($0) }
}

func sample_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count <= 32 {
        insertion_sort(a)
        return
    }
    let sample_count = Int((Double(a.count)).squareRoot())
    let step = max(a.count / max(sample_count, 1), 1)
    var splitters = [Int]()
    var si = step - 1
    while si < a.count && splitters.count < sample_count {
        splitters.append(a[si])
        si += step
    }
    quick_sort(&splitters)
    // A single distinct splitter sends every element to bucket 0, so recursing would
    // never shrink the input (33+ equal keys); finish such a run with quick sort.
    if splitters.first == splitters.last {
        quick_sort(a)
        return
    }
    var buckets = [[Int]](repeating: [], count: splitters.count + 1)
    for i in 0..<a.count {
        let value = a[i]
        // partition_point where predicate value > splitter is false
        var lo = 0
        var hi = splitters.count
        while lo < hi {
            let mid = lo + (hi - lo) / 2
            if value > splitters[mid] {
                lo = mid + 1
            } else {
                hi = mid
            }
        }
        buckets[lo].append(value)
    }
    var pos = 0
    for b in 0..<buckets.count {
        sample_sort(&buckets[b])
        for value in buckets[b] {
            a[pos] = value
            pos += 1
        }
    }
}
