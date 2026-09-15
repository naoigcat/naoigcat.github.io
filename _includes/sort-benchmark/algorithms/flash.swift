private func flash_class_index(_ x: Int, _ minVal: Int, _ maxVal: Int, _ m: Int) -> Int {
    if maxVal == minVal {
        return 0
    } else {
        return Int(Double(x - minVal) / Double(maxVal - minVal) * Double(m - 1))
    }
}

func flash_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { flash_sort($0) }
}

func flash_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }

    var lo = a[0]
    var hi = a[0]
    for i in 1..<n {
        if a[i] < lo { lo = a[i] }
        if a[i] > hi { hi = a[i] }
    }
    if lo == hi {
        return
    }

    let mRaw = Int((Double(n) * log2(2.0 * Double(n))).squareRoot().rounded(.up))
    let m = Swift.min(Swift.max(mRaw, 2), n)

    var count = [Int](repeating: 0, count: m)
    for i in 0..<n {
        count[flash_class_index(a[i], lo, hi, m)] += 1
    }

    var boundary = [Int](repeating: 0, count: m + 1)
    for i in 0..<m {
        boundary[i + 1] = boundary[i] + count[i]
    }

    var temp = [Int](repeating: 0, count: n)
    var cursor = boundary
    for i in 0..<n {
        let k = flash_class_index(a[i], lo, hi, m)
        temp[cursor[k]] = a[i]
        cursor[k] += 1
    }
    for i in 0..<n {
        a[i] = temp[i]
    }

    for i in 0..<m {
        let start = boundary[i]
        let end = boundary[i + 1]
        if end - start > 1 {
            insertion_sort(UnsafeMutableBufferPointer(rebasing: a[start..<end]))
        }
    }
}
