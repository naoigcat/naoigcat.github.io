fileprivate struct PowerRun {
    var lo: Int
    var hi: Int
    var power: UInt32
}

fileprivate func node_power(_ n: Int, _ b1: Int, _ e1: Int, _ b2: Int, _ e2: Int) -> UInt32 {
    let a = (Double(b1) + Double(e1 - b1) / 2.0) / Double(n)
    let b = (Double(b2) + Double(e2 - b2) / 2.0) / Double(n)
    var p: UInt32 = 0
    while floor(a * pow(2.0, Double(p))) == floor(b * pow(2.0, Double(p))) {
        p += 1
    }
    return p
}

fileprivate func merge_power_runs(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ left: PowerRun,
    _ right: PowerRun
) -> PowerRun {
    let lo = left.lo
    let hi = right.hi
    let mid = left.hi + 1
    var merged = [Int]()
    merged.reserveCapacity(hi - lo + 1)
    var l = left.lo
    var r = mid
    while l <= left.hi && r <= right.hi {
        if a[l] <= a[r] {
            merged.append(a[l])
            l += 1
        } else {
            merged.append(a[r])
            r += 1
        }
    }
    while l <= left.hi {
        merged.append(a[l])
        l += 1
    }
    while r <= right.hi {
        merged.append(a[r])
        r += 1
    }
    for i in 0..<merged.count {
        a[lo + i] = merged[i]
    }
    return PowerRun(lo: lo, hi: hi, power: 0)
}

fileprivate func prepare_power_run(_ a: UnsafeMutableBufferPointer<Int>, _ start: Int, _ min_run: Int) -> Int {
    let n = a.count
    var i = start + 1
    if i < n && a[i - 1] > a[i] {
        while i < n && a[i - 1] > a[i] {
            i += 1
        }
        var lo = start
        var hi = i - 1
        while lo < hi {
            a.swapAt(lo, hi)
            lo += 1
            hi -= 1
        }
    } else {
        while i < n && a[i - 1] <= a[i] {
            i += 1
        }
    }
    let end = max(min(start + min_run, n), i)
    insertion_sort(UnsafeMutableBufferPointer(rebasing: a[start..<end]))
    return end
}

func power_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { power_sort($0) }
}

func power_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let MIN_RUN = 32
    let n = a.count
    if n <= 1 {
        return
    }
    var stack: [PowerRun] = []
    var b1 = 0
    var e1 = prepare_power_run(a, 0, MIN_RUN)
    while e1 < n {
        let b2 = e1
        let e2 = prepare_power_run(a, b2, MIN_RUN)
        let p = node_power(n, b1, e1, b2, e2)
        while let top = stack.last, top.power > p {
            let top = stack.removeLast()
            let cur = PowerRun(lo: b1, hi: e1 - 1, power: 0)
            let merged = merge_power_runs(a, top, cur)
            b1 = merged.lo
            e1 = merged.hi + 1
        }
        stack.append(PowerRun(lo: b1, hi: e1 - 1, power: p))
        b1 = b2
        e1 = e2
    }
    while !stack.isEmpty {
        let top = stack.removeLast()
        let cur = PowerRun(lo: b1, hi: e1 - 1, power: 0)
        let merged = merge_power_runs(a, top, cur)
        b1 = merged.lo
        e1 = merged.hi + 1
    }
}
