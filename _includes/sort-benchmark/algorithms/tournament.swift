func tournament_winner(_ a: UnsafeMutableBufferPointer<Int>, _ left: Int, _ right: Int) -> Int {
    if left == Int.max {
        return right
    }
    if right == Int.max {
        return left
    }
    if a[left] <= a[right] {
        return left
    } else {
        return right
    }
}

func tournament_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { tournament_sort($0) }
}

func tournament_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    // next_power_of_two(n)
    let k = 1 << (Int.bitWidth - (n - 1).leadingZeroBitCount)
    var tree = [Int](repeating: 0, count: 2 * k)
    for i in 0..<k {
        tree[k + i] = i < n ? i : Int.max
    }
    for i in (1..<k).reversed() {
        tree[i] = tournament_winner(a, tree[2 * i], tree[2 * i + 1])
    }
    var out = [Int](repeating: 0, count: n)
    for pos in 0..<n {
        let idx = tree[1]
        out[pos] = a[idx]
        a[idx] = Int.max
        var node = k + idx
        tree[node] = Int.max
        while node > 1 {
            node /= 2
            tree[node] = tournament_winner(a, tree[2 * node], tree[2 * node + 1])
        }
    }
    for i in 0..<n {
        a[i] = out[i]
    }
}
