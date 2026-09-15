func self_indexed_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { self_indexed_sort($0) }
}

func self_indexed_sort(_ a: UnsafeMutableBufferPointer<Int>) {
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

    // Phase 1: initialize sorting space
    var ss = [Int](repeating: 0, count: span)

    // Phase 2: self-indexed arrangement (key maps to offset in ss)
    for i in 0..<a.count {
        ss[a[i] - min] += 1
    }

    // Phase 3: order-preserved compression back into the original array
    var idx = 0

    for offset in 0..<ss.count {
        let cnt = ss[offset]
        let value = min + offset
        for _ in 0..<cnt {
            a[idx] = value
            idx += 1
        }
    }
}
