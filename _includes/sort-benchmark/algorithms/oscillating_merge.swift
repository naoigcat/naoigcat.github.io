/// Oscillating merge sort (Sobel 1962), in-memory pedagogical simulation.
///
/// Classic tape form uses n drives (1 input + n−1 work) and an (n−2)-way merge.
/// Here n = 5 ⇒ WAY = 3 work inputs per merge and NUM_TAPES = WAY + 1 = 4 work
/// tapes in the narrative; we store runs by merge level instead of physical tapes.
/// Distribution of initial runs and merging are interleaved: after every WAY new
/// level-0 runs, collapse any level that has WAY pending runs into the next level
/// (batches grow as powers of WAY). Remaining runs are flushed with the same
/// k-way merge at the end.
fileprivate let RUN_SIZE = 32
fileprivate let WAY = 3

fileprivate func merge_k_way(_ runs: [[Int]]) -> [Int] {
    let k = runs.count
    var heads = [Int](repeating: 0, count: k)
    let total = runs.reduce(0) { $0 + $1.count }
    var out = [Int]()
    out.reserveCapacity(total)

    while true {
        var best: (Int, Int)? = nil
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

fileprivate func create_runs(_ a: UnsafeMutableBufferPointer<Int>, _ run_size: Int) -> [[Int]] {
    var runs: [[Int]] = []
    var i = 0
    while i < a.count {
        let end = min(i + run_size, a.count)
        var run = Array(a[i..<end])
        run.sort()
        runs.append(run)
        i = end
    }
    return runs
}

fileprivate func collapse_from(_ by_level: inout [[ [Int] ]], _ level: Int) {
    while level < by_level.count && by_level[level].count >= WAY {
        var batch: [[Int]] = []
        batch.reserveCapacity(WAY)
        for _ in 0..<WAY {
            batch.append(by_level[level].removeFirst())
        }
        let merged = merge_k_way(batch)
        let next = level + 1
        while by_level.count <= next {
            by_level.append([])
        }
        by_level[next].append(merged)
        collapse_from(&by_level, next)
    }
}

func oscillating_merge_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { oscillating_merge_sort($0) }
}

func oscillating_merge_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count <= 1 {
        return
    }

    let pending = create_runs(a, RUN_SIZE)
    if pending.count <= 1 {
        if let r = pending.first {
            for i in 0..<a.count {
                a[i] = r[i]
            }
        }
        return
    }

    var by_level: [[[Int]]] = [[]]
    var index = 0
    while index < pending.count {
        var placed = 0
        while placed < WAY && index < pending.count {
            by_level[0].append(pending[index])
            index += 1
            placed += 1
            collapse_from(&by_level, 0)
        }
    }

    var leftover: [[Int]] = []
    for level in 0..<by_level.count {
        leftover.append(contentsOf: by_level[level])
    }
    while leftover.count > 1 {
        let k = min(WAY, leftover.count)
        let batch = Array(leftover.prefix(k))
        leftover.removeFirst(k)
        leftover.append(merge_k_way(batch))
    }

    let result = leftover.first ?? []
    for i in 0..<a.count {
        a[i] = result[i]
    }
}
