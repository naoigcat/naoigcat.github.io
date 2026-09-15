final class SleepShared {
    var output: [Int]
    let lock = NSLock()
    init(_ n: Int) {
        output = [Int](repeating: 0, count: n)
    }
}

func sleep_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { sleep_sort($0) }
}

func sleep_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.isEmpty {
        return
    }

    let n = a.count
    // Measurement convenience: pick stable output slots by comparing values first.
    // Threads still sleep so wall time tracks a capped max(A), but the published
    // order must not depend on OS scheduling across thousands of benchmark runs.
    // Article demos append in true wake order; this harness path does not.
    var order = Array(0..<n)
    order.sort { i, j in
        if a[i] != a[j] {
            return a[i] < a[j]
        }
        return i < j
    }

    var rank = [Int](repeating: 0, count: n)
    for (r, i) in order.enumerated() {
        rank[i] = r
    }

    let shared = SleepShared(n)
    var threads = [Thread]()
    threads.reserveCapacity(n)

    for idx in 0..<n {
        let value = a[idx]
        let slot = rank[idx]
        let thread = Thread {
            let scaled = min(value, 10_000)
            let micros = scaled * 100 + idx * 10
            usleep(useconds_t(micros))
            shared.lock.lock()
            shared.output[slot] = value
            shared.lock.unlock()
        }
        threads.append(thread)
        thread.start()
    }

    for thread in threads {
        while !thread.isFinished {
            usleep(100)
        }
    }

    shared.lock.lock()
    let sorted = shared.output
    shared.lock.unlock()
    for i in 0..<n {
        a[i] = sorted[i]
    }
}
