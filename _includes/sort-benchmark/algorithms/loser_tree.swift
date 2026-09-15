fileprivate func player_key(_ a: UnsafeMutableBufferPointer<Int>, _ idx: Int) -> Int {
    if idx == Int.max {
        return Int.max
    } else {
        return a[idx]
    }
}

fileprivate func next_power_of_two(_ n: UInt) -> UInt {
    if n <= 1 {
        return 1
    }
    var v = n - 1
    v |= v >> 1
    v |= v >> 2
    v |= v >> 4
    v |= v >> 8
    v |= v >> 16
    v |= v >> 32
    return v + 1
}

fileprivate func loser_and_winner(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ left: Int,
    _ right: Int
) -> (Int, Int) {
    if left == Int.max {
        return (Int.max, right)
    }
    if right == Int.max {
        return (Int.max, left)
    }
    if player_key(a, left) <= player_key(a, right) {
        return (right, left)
    } else {
        return (left, right)
    }
}

fileprivate func adjust_loser_tree(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ ls: inout [Int],
    _ k: Int,
    _ s: Int
) {
    var s = s
    var t = (s + k) / 2
    while t > 0 {
        if player_key(a, s) > player_key(a, ls[t]) {
            let tmp = s
            s = ls[t]
            ls[t] = tmp
        }
        t /= 2
    }
    ls[0] = s
}

func loser_tree_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { loser_tree_sort($0) }
}

func loser_tree_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    let k = Int(next_power_of_two(UInt(n)))
    var ls = [Int](repeating: Int.max, count: k)
    var winner = [Int](repeating: Int.max, count: 2 * k)
    for i in 0..<k {
        winner[k + i] = i < n ? i : Int.max
    }
    for i in (1..<k).reversed() {
        let (loser, win) = loser_and_winner(a, winner[2 * i], winner[2 * i + 1])
        ls[i] = loser
        winner[i] = win
    }
    ls[0] = winner[1]

    var out = [Int](repeating: 0, count: n)
    for pos in 0..<n {
        let idx = ls[0]
        out[pos] = a[idx]
        a[idx] = Int.max
        adjust_loser_tree(a, &ls, k, idx)
    }
    for i in 0..<n {
        a[i] = out[i]
    }
}
