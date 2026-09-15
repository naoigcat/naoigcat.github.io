func counting_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { counting_sort($0) }
}

func counting_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.isEmpty {
        return
    }

    var min = a[0]
    var max = a[0]
    for i in 1..<a.count {
        if a[i] < min { min = a[i] }
        if a[i] > max { max = a[i] }
    }
    let span = max - min + 1
    var count = [Int](repeating: 0, count: span)

    for i in 0..<a.count {
        count[a[i] - min] += 1
    }

    var idx = 0
    for offset in 0..<count.count {
        let value = min + offset
        let cnt = count[offset]
        for _ in 0..<cnt {
            a[idx] = value
            idx += 1
        }
    }
}
