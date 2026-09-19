/// Educational gridsort: insert into a 2-axis binary grid (lookup floors → Y buckets),
/// bulk-sort and split overflowing buckets, then flatten in floor order.
/// Stand-in for scandum's gridsort (production uses monobound/adaptive searches and
/// quadsort for bucket sorts). Capacity tracks ~√n so roughly 2√n buckets of √n fit.

fileprivate func grid_capacity(_ n: Int) -> Int {
    var c = 4
    while c * c < n {
        c *= 2
        if c > 512 {
            return 512
        }
    }
    return c
}

fileprivate struct GridBucket {
    var floor: Int
    var items: [Int]
    var isSorted: Bool

    mutating func ensureSorted() {
        if isSorted {
            return
        }
        insertion_sort(&items)
        isSorted = true
        if let first = items.first {
            floor = first
        }
    }
}

fileprivate func grid_find(_ buckets: [GridBucket], _ key: Int) -> Int {
    var lo = 0
    var hi = buckets.count
    while lo < hi {
        let mid = lo + (hi - lo) / 2
        if buckets[mid].floor <= key {
            lo = mid + 1
        } else {
            hi = mid
        }
    }
    return max(0, lo - 1)
}

fileprivate func grid_split(_ buckets: inout [GridBucket], _ bi: Int) {
    buckets[bi].ensureSorted()
    let mid = buckets[bi].items.count / 2
    guard mid > 0, mid < buckets[bi].items.count else {
        return
    }
    let rightItems = Array(buckets[bi].items[mid...])
    buckets[bi].items.removeSubrange(mid...)
    buckets[bi].floor = buckets[bi].items[0]
    buckets[bi].isSorted = true
    buckets.insert(
        GridBucket(floor: rightItems[0], items: rightItems, isSorted: true),
        at: bi + 1
    )
}

func grid_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { grid_sort($0) }
}

func grid_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n < 2 {
        return
    }

    let capacity = grid_capacity(n)
    var first = GridBucket(floor: a[0], items: [], isSorted: true)
    first.items.reserveCapacity(capacity)
    first.items.append(a[0])
    var buckets: [GridBucket] = [first]

    for i in 1..<n {
        let key = a[i]
        let bi = grid_find(buckets, key)

        if buckets[bi].items.capacity < capacity {
            buckets[bi].items.reserveCapacity(capacity)
        }
        buckets[bi].items.append(key)
        buckets[bi].isSorted = false

        if buckets[bi].items.count >= capacity {
            grid_split(&buckets, bi)
        }
    }

    var out = [Int]()
    out.reserveCapacity(n)
    for bi in 0..<buckets.count {
        buckets[bi].ensureSorted()
        out.append(contentsOf: buckets[bi].items)
    }
    for i in 0..<n {
        a[i] = out[i]
    }
}
