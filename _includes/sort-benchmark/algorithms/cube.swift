/// Educational cubesort: insert into a balanced 3-axis binary cube (X → Y → Z),
/// bulk-sort and split overflowing Z buckets, then flatten in axis order.
/// Stand-in for scandum's cubesort / binary-cube partitioning (production uses
/// monobound searches and quadsort for bucket sorts).

fileprivate func cube_capacity(_ n: Int) -> Int {
    var c = 4
    while c * c * c < n {
        c *= 2
        if c > 256 {
            return 256
        }
    }
    return c
}

fileprivate struct CubeZBucket {
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

fileprivate struct CubeYNode {
    var zs: [CubeZBucket]

    var floor: Int { zs[0].floor }
}

fileprivate func cube_find_y(_ xs: [CubeYNode], _ key: Int) -> Int {
    var lo = 0
    var hi = xs.count
    while lo < hi {
        let mid = lo + (hi - lo) / 2
        if xs[mid].floor <= key {
            lo = mid + 1
        } else {
            hi = mid
        }
    }
    return max(0, lo - 1)
}

fileprivate func cube_find_z(_ zs: [CubeZBucket], _ key: Int) -> Int {
    var lo = 0
    var hi = zs.count
    while lo < hi {
        let mid = lo + (hi - lo) / 2
        if zs[mid].floor <= key {
            lo = mid + 1
        } else {
            hi = mid
        }
    }
    return max(0, lo - 1)
}

fileprivate func cube_split_z(_ y: inout CubeYNode, _ zi: Int, _ capacity: Int) -> Bool {
    y.zs[zi].ensureSorted()
    let mid = y.zs[zi].items.count / 2
    guard mid > 0, mid < y.zs[zi].items.count else {
        return false
    }
    let rightItems = Array(y.zs[zi].items[mid...])
    y.zs[zi].items.removeSubrange(mid...)
    y.zs[zi].floor = y.zs[zi].items[0]
    y.zs[zi].isSorted = true
    y.zs.insert(
        CubeZBucket(floor: rightItems[0], items: rightItems, isSorted: true),
        at: zi + 1
    )
    return y.zs.count > capacity * 2
}

fileprivate func cube_split_y(_ xs: inout [CubeYNode], _ yi: Int) {
    let mid = xs[yi].zs.count / 2
    guard mid > 0, mid < xs[yi].zs.count else {
        return
    }
    let rightZs = Array(xs[yi].zs[mid...])
    xs[yi].zs.removeSubrange(mid...)
    xs.insert(CubeYNode(zs: rightZs), at: yi + 1)
}

func cube_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { cube_sort($0) }
}

func cube_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n < 2 {
        return
    }

    let capacity = cube_capacity(n)
    var first = CubeZBucket(floor: a[0], items: [], isSorted: true)
    first.items.reserveCapacity(capacity)
    first.items.append(a[0])
    var xs: [CubeYNode] = [CubeYNode(zs: [first])]

    for i in 1..<n {
        let key = a[i]
        let yi = cube_find_y(xs, key)
        let zi = cube_find_z(xs[yi].zs, key)

        if xs[yi].zs[zi].items.capacity < capacity {
            xs[yi].zs[zi].items.reserveCapacity(capacity)
        }
        xs[yi].zs[zi].items.append(key)
        xs[yi].zs[zi].isSorted = false

        if xs[yi].zs[zi].items.count >= capacity {
            if cube_split_z(&xs[yi], zi, capacity) {
                cube_split_y(&xs, yi)
            }
        }
    }

    var out = [Int]()
    out.reserveCapacity(n)
    for yi in 0..<xs.count {
        for zi in 0..<xs[yi].zs.count {
            xs[yi].zs[zi].ensureSorted()
            out.append(contentsOf: xs[yi].zs[zi].items)
        }
    }
    for i in 0..<n {
        a[i] = out[i]
    }
}
