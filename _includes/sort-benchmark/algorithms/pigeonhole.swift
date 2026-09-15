func pigeonhole_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { pigeonhole_sort($0) }
}

func pigeonhole_sort(_ a: UnsafeMutableBufferPointer<Int>) {
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
    var holes = [[Int]](repeating: [], count: span)

    for i in 0..<a.count {
        let x = a[i]
        holes[x - min].append(x)
    }

    var idx = 0
    for hole in holes {
        for x in hole {
            a[idx] = x
            idx += 1
        }
    }
}
