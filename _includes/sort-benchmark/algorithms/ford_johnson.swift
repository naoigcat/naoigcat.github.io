private func ford_johnson_insert_order(_ m: Int) -> [Int] {
    if m == 0 {
        return []
    }
    var js = [0, 1]
    while js.last! < m {
        let l = js.count
        js.append(js[l - 1] + 2 * js[l - 2])
    }
    var order = [Int]()
    var used = [Bool](repeating: false, count: m)
    var prev_j = 0
    for j in js.dropFirst() {
        if j > m {
            break
        }
        if j > prev_j {
            for idx in stride(from: j - 1, through: prev_j, by: -1) {
                if idx < m && !used[idx] {
                    order.append(idx)
                    used[idx] = true
                }
            }
            prev_j = j
        }
    }
    for idx in stride(from: m - 1, through: 0, by: -1) {
        if !used[idx] {
            order.append(idx)
        }
    }
    return order
}

private func ford_johnson_reorder_pairs(
    _ pairs: [(Int, Int)],
    _ sorted_larges: [Int]
) -> [(Int, Int)] {
    var out = [(Int, Int)]()
    out.reserveCapacity(sorted_larges.count)
    var taken = [Bool](repeating: false, count: pairs.count)
    for lg in sorted_larges {
        for (i, p) in pairs.enumerated() {
            if !taken[i] && p.1 == lg {
                out.append(p)
                taken[i] = true
                break
            }
        }
    }
    return out
}

func ford_johnson(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { ford_johnson($0) }
}

func ford_johnson(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    if n == 2 {
        if a[0] > a[1] {
            a.swapAt(0, 1)
        }
        return
    }
    let pair_count = n / 2
    var pairs = [(Int, Int)]()
    pairs.reserveCapacity(pair_count)
    for i in 0..<pair_count {
        let lo = 2 * i
        let hi = lo + 1
        if a[lo] > a[hi] {
            pairs.append((a[hi], a[lo]))
        } else {
            pairs.append((a[lo], a[hi]))
        }
    }
    let odd: Int? = n % 2 == 1 ? a[n - 1] : nil
    var larges = pairs.map { $0.1 }
    ford_johnson(&larges)
    let sorted_pairs = ford_johnson_reorder_pairs(pairs, larges)
    var chain = [Int]()
    chain.reserveCapacity(n)
    chain.append(sorted_pairs[0].0)
    chain.append(contentsOf: sorted_pairs.map { $0.1 })
    var pending_pairs = Array(sorted_pairs.dropFirst())
    if let v = odd {
        pending_pairs.append((v, Int.max))
    }
    let pending = pending_pairs.map { $0.0 }
    for idx in ford_johnson_insert_order(pending.count) {
        let val = pending[idx]
        let limit: Int
        if pending_pairs[idx].1 == Int.max {
            limit = chain.count
        } else {
            limit = chain.firstIndex(of: pending_pairs[idx].1) ?? chain.count
        }
        var pos = 0
        while pos < limit && chain[pos] < val {
            pos += 1
        }
        chain.insert(val, at: pos)
    }
    for i in 0..<n {
        a[i] = chain[i]
    }
}
