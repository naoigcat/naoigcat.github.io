func cycle_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { cycle_sort($0) }
}

func cycle_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    for cycle_start in 0..<(n - 1) {
        var item = a[cycle_start]
        var pos = cycle_start
        for i in (cycle_start + 1)..<n {
            if a[i] < item {
                pos += 1
            }
        }
        if pos == cycle_start {
            continue
        }
        while pos < n && a[pos] == item {
            pos += 1
        }
        let t0 = a[pos]; a[pos] = item; item = t0
        while pos != cycle_start {
            pos = cycle_start
            for i in (cycle_start + 1)..<n {
                if a[i] < item {
                    pos += 1
                }
            }
            while pos < n && a[pos] == item {
                pos += 1
            }
            let t1 = a[pos]; a[pos] = item; item = t1
        }
    }
}
