struct ShiversRun {
    var lo: Int
    var hi: Int
}

func run_level(_ len: Int) -> UInt32 {
    UInt32(Int.bitWidth - 1 - len.leadingZeroBitCount)
}

func merge_shivers_runs(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ left: ShiversRun,
    _ right: ShiversRun
) -> ShiversRun {
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
    if l <= left.hi {
        for i in l...left.hi {
            merged.append(a[i])
        }
    }
    if r <= right.hi {
        for i in r...right.hi {
            merged.append(a[i])
        }
    }
    for i in 0..<merged.count {
        a[lo + i] = merged[i]
    }
    return ShiversRun(lo: lo, hi: hi)
}

func prepare_shivers_run(_ a: UnsafeMutableBufferPointer<Int>, _ start: Int, _ min_run: Int) -> Int {
    let n = a.count
    var i = start + 1
    if i < n && a[i - 1] > a[i] {
        while i < n && a[i - 1] > a[i] {
            i += 1
        }
        var lo = start
        var hi = i
        while lo + 1 < hi {
            hi -= 1
            a.swapAt(lo, hi)
            lo += 1
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

func adaptive_shivers_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { adaptive_shivers_sort($0) }
}

func adaptive_shivers_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let MIN_RUN = 32
    let n = a.count
    if n <= 1 {
        return
    }

    var pending = [ShiversRun]()
    var start = 0
    while start < n {
        let end = prepare_shivers_run(a, start, MIN_RUN)
        pending.append(ShiversRun(lo: start, hi: end - 1))
        start = end
    }

    var stack = [ShiversRun]()
    var next = 0
    while true {
        let h = stack.count
        if h >= 3 {
            let r_hm2 = stack[h - 3]
            let r_hm1 = stack[h - 2]
            let r_h = stack[h - 1]
            let ell_hm2 = run_level(r_hm2.hi - r_hm2.lo + 1)
            let ell_hm1 = run_level(r_hm1.hi - r_hm1.lo + 1)
            let ell_h = run_level(r_h.hi - r_h.lo + 1)
            if ell_hm2 <= max(ell_hm1, ell_h) {
                let top = stack.removeLast()
                let mid = stack.removeLast()
                let left = stack.removeLast()
                let merged = merge_shivers_runs(a, left, mid)
                stack.append(merged)
                stack.append(top)
                continue
            }
        }
        if next < pending.count {
            stack.append(pending[next])
            next += 1
            continue
        }
        break
    }

    while stack.count >= 2 {
        let right = stack.removeLast()
        let left = stack.removeLast()
        stack.append(merge_shivers_runs(a, left, right))
    }
}
