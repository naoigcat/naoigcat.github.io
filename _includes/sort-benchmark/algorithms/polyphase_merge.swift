fileprivate let NUM_TAPES = 3
fileprivate let RUN_SIZE = 32

fileprivate func merge_runs(_ left: [Int], _ right: [Int]) -> [Int] {
    merge_values(left, right)
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

fileprivate func next_fibonacci_at_least(_ n: Int) -> (Int, Int) {
    var prev = 1
    var curr = 1
    while curr < n {
        let next = prev + curr
        prev = curr
        curr = next
    }
    return (prev, curr)
}

fileprivate func distribute_fibonacci(_ runs: [[Int]]) -> [[[Int]]] {
    var tapes: [[[Int]]] = [[], [], []]
    let n = runs.count
    if n == 0 {
        return tapes
    }
    if n == 1 {
        tapes[1].append(runs[0])
        return tapes
    }

    let (fib_prev, fib_target) = next_fibonacci_at_least(n)
    let dummies = fib_target - n
    let on_tape2 = max(0, fib_prev - dummies)
    let on_tape1 = n - on_tape2

    for (idx, run) in runs.enumerated() {
        if idx < on_tape1 {
            tapes[1].append(run)
        } else {
            tapes[2].append(run)
        }
    }
    return tapes
}

fileprivate func count_runs(_ tapes: [[[Int]]]) -> Int {
    tapes.reduce(0) { $0 + $1.count }
}

fileprivate func rotate_tapes(_ tapes: inout [[[Int]]]) {
    tapes.swapAt(0, 1)
    tapes.swapAt(1, 2)
}

fileprivate func polyphase_pass(_ tapes: inout [[[Int]]]) -> Bool {
    var merged = false
    while !tapes[1].isEmpty && !tapes[2].isEmpty {
        let left = tapes[1].removeFirst()
        let right = tapes[2].removeFirst()
        tapes[0].append(merge_runs(left, right))
        merged = true
    }
    return merged
}

fileprivate func merge_all_remaining(_ tapes: inout [[[Int]]]) -> [Int] {
    var all: [[Int]] = []
    for tape in tapes {
        all.append(contentsOf: tape)
    }
    while all.count > 1 {
        let a = all.removeFirst()
        let b = all.removeFirst()
        all.append(merge_runs(a, b))
    }
    return all.popLast() ?? []
}

func polyphase_merge_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { polyphase_merge_sort($0) }
}

func polyphase_merge_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count <= 1 {
        return
    }
    let runs = create_runs(a, RUN_SIZE)
    if runs.count <= 1 {
        if let r = runs.first {
            for i in 0..<a.count {
                a[i] = r[i]
            }
        }
        return
    }

    var tapes = distribute_fibonacci(runs)
    var idle = 0
    while count_runs(tapes) > 1 {
        if polyphase_pass(&tapes) {
            rotate_tapes(&tapes)
            idle = 0
        } else {
            idle += 1
            if idle > NUM_TAPES * 4 {
                break
            }
            rotate_tapes(&tapes)
        }
    }

    let result: [Int]
    if count_runs(tapes) == 1 {
        result = tapes.compactMap { $0.first }.first ?? []
    } else {
        result = merge_all_remaining(&tapes)
    }
    for i in 0..<a.count {
        a[i] = result[i]
    }
}
