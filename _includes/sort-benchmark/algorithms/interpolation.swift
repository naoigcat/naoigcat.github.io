private let INTERPOLATION_INSERTION_THRESHOLD = 16

private func interpolation_index(
    _ x: Int,
    _ minVal: Int,
    _ maxVal: Int,
    _ n: Int
) -> Int {
    if maxVal == minVal {
        return 0
    } else {
        return Int(
            (Double(x - minVal) / Double(maxVal - minVal) * Double(n - 1))
                .rounded(.down)
        )
    }
}

func interpolation_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { interpolation_sort($0) }
}

func interpolation_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    if n <= INTERPOLATION_INSERTION_THRESHOLD {
        insertion_sort(a)
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

    var count = [Int](repeating: 0, count: n)
    for i in 0..<n {
        count[interpolation_index(a[i], lo, hi, n)] += 1
    }

    var boundary = [Int](repeating: 0, count: n + 1)
    for i in 0..<n {
        boundary[i + 1] = boundary[i] + count[i]
    }

    var temp = [Int](repeating: 0, count: n)
    var cursor = boundary
    for i in 0..<n {
        let k = interpolation_index(a[i], lo, hi, n)
        temp[cursor[k]] = a[i]
        cursor[k] += 1
    }
    for i in 0..<n {
        a[i] = temp[i]
    }

    for i in 0..<n {
        let start = boundary[i]
        let end = boundary[i + 1]
        if end - start > 1 {
            interpolation_sort(UnsafeMutableBufferPointer(rebasing: a[start..<end]))
        }
    }
}
