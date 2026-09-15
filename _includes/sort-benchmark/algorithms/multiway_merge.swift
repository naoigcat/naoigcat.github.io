/// Branching factor for multiway (k-way) merge sort. Fixed for the pedagogical
/// benchmark so asymptotics stay Θ(n log n) with a constant-factor log_k.
fileprivate let WAY = 4

/// Stable k-way merge: when heads compare equal, the leftmost run wins.
fileprivate func merge_k_way(_ runs: [[Int]]) -> [Int] {
    let k = runs.count
    var heads = [Int](repeating: 0, count: k)
    let total = runs.reduce(0) { $0 + $1.count }
    var out = [Int]()
    out.reserveCapacity(total)

    while true {
        var best: (Int, Int)? = nil  // (run_index, value)
        for i in 0..<k {
            if heads[i] < runs[i].count {
                let v = runs[i][heads[i]]
                if let (bi, bv) = best {
                    if v < bv || (v == bv && i < bi) {
                        best = (i, v)
                    }
                } else {
                    best = (i, v)
                }
            }
        }
        guard let (i, v) = best else {
            break
        }
        out.append(v)
        heads[i] += 1
    }
    return out
}

func multiway_merge_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { multiway_merge_sort($0) }
}

func multiway_merge_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }

    var bounds = [(Int, Int)]()
    bounds.reserveCapacity(WAY)
    let base = n / WAY
    let rem = n % WAY
    var start = 0
    for i in 0..<WAY {
        let len = base + (i < rem ? 1 : 0)
        if len == 0 {
            continue
        }
        let end = start + len
        multiway_merge_sort(UnsafeMutableBufferPointer(rebasing: a[start..<end]))
        bounds.append((start, end))
        start = end
    }

    if bounds.count <= 1 {
        return
    }

    var runs = [[Int]]()
    runs.reserveCapacity(bounds.count)
    for (lo, hi) in bounds {
        var run = [Int]()
        run.reserveCapacity(hi - lo)
        for i in lo..<hi {
            run.append(a[i])
        }
        runs.append(run)
    }
    let merged = merge_k_way(runs)
    for i in 0..<n {
        a[i] = merged[i]
    }
}
