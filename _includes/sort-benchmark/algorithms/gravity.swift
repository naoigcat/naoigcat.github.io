func gravity_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { gravity_sort($0) }
}

func gravity_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count == 0 {
        return
    }

    var max = a[0]
    for i in 1..<a.count {
        if a[i] > max {
            max = a[i]
        }
    }
    if max == 0 {
        return
    }

    var beads = [Int](repeating: 0, count: max)

    for i in 0..<a.count {
        let x = a[i]
        for j in 0..<x {
            beads[j] += 1
        }
    }

    let n = a.count
    for i in (0..<n).reversed() {
        var sum = 0
        for j in 0..<beads.count {
            if beads[j] == 0 {
                break
            }
            sum += 1
            beads[j] -= 1
        }
        a[i] = sum
    }
}
