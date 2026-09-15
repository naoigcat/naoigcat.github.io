func spaghetti_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { spaghetti_sort($0) }
}

func spaghetti_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n < 2 {
        return
    }

    // Physical model: remove the longest remaining stick repeatedly (descending),
    // then reverse for ascending order. Digital simulation uses O(n) scratch space.
    var sticks = [Int](repeating: 0, count: n)
    for i in 0..<n {
        sticks[i] = a[i]
    }
    var descending = [Int]()
    descending.reserveCapacity(n)

    while !sticks.isEmpty {
        var max_idx = 0
        for i in 1..<sticks.count {
            if sticks[i] > sticks[max_idx] {
                max_idx = i
            }
        }
        sticks.swapAt(max_idx, sticks.count - 1)
        descending.append(sticks.removeLast())
    }

    descending.reverse()
    for i in 0..<n {
        a[i] = descending[i]
    }
}
