func bucket_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { bucket_sort($0) }
}

func bucket_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.isEmpty {
        return
    }

    let n = a.count
    let min = a.min()!
    let max = a.max()!
    let bucket_count = n
    var buckets = Array(repeating: [Int](), count: bucket_count)

    for i in 0..<n {
        let x = a[i]
        let idx: Int
        if max == min {
            idx = 0
        } else {
            idx = Int((Double(x - min) / Double(max - min) * Double(bucket_count - 1)).rounded(.down))
        }
        buckets[idx].append(x)
    }

    for i in 0..<buckets.count {
        insertion_sort(&buckets[i])
    }

    var idx = 0
    for bucket in buckets {
        for x in bucket {
            a[idx] = x
            idx += 1
        }
    }
}
