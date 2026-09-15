final class VebTree {
    var universe: Int
    var min: Int?
    var max: Int?
    var summary: VebTree?
    var cluster: [VebTree?]

    init(universe: Int) {
        assert(universe > 0 && (universe & (universe - 1)) == 0)
        assert(universe >= 2)

        self.universe = universe
        self.min = nil
        self.max = nil

        if universe == 2 {
            self.summary = nil
            self.cluster = []
            return
        }

        let lower = VebTree.lower_sqrt(universe)
        let upper = universe / lower

        self.summary = VebTree(universe: upper)
        self.cluster = Array(repeating: nil, count: upper)
    }

    static func lower_sqrt(_ universe: Int) -> Int {
        1 << (universe.trailingZeroBitCount / 2)
    }

    func high(_ x: Int) -> Int {
        x / VebTree.lower_sqrt(universe)
    }

    func low(_ x: Int) -> Int {
        x % VebTree.lower_sqrt(universe)
    }

    func index(_ high: Int, _ low: Int) -> Int {
        high * VebTree.lower_sqrt(universe) + low
    }

    func minimum() -> Int? {
        min
    }

    func maximum() -> Int? {
        max
    }

    func cluster_mut(_ i: Int) -> VebTree {
        let lower = VebTree.lower_sqrt(universe)
        if cluster[i] == nil {
            cluster[i] = VebTree(universe: lower)
        }
        return cluster[i]!
    }

    func empty_insert(_ x: Int) {
        min = x
        max = x
    }

    func insert(_ x: Int) {
        var x = x
        if min == nil {
            empty_insert(x)
            return
        }

        if x < min! {
            let old_min = min!
            min = x
            x = old_min
        }

        if universe > 2 {
            let h = high(x)
            let l = low(x)
            if cluster[h]?.minimum() == nil {
                summary!.insert(h)
                cluster_mut(h).empty_insert(l)
            } else {
                cluster_mut(h).insert(l)
            }
        }

        if x > max! {
            max = x
        }
    }

    func successor(_ x: Int) -> Int? {
        if universe == 2 {
            if x == 0 && max == 1 {
                return 1
            } else {
                return nil
            }
        }

        if let min = min {
            if x < min {
                return min
            }
        } else {
            return nil
        }

        let h = high(x)
        let l = low(x)
        let max_low = cluster[h]?.maximum()
        if let m = max_low, l < m {
            let offset = cluster[h]!.successor(l)!
            return index(h, offset)
        }

        guard let succ_cluster = summary!.successor(h) else {
            return nil
        }
        let offset = cluster[succ_cluster]!.minimum()!
        return index(succ_cluster, offset)
    }
}

func next_power_of_two(_ n: Int) -> Int {
    if n <= 1 {
        return 1
    }
    var v = UInt(bitPattern: n - 1)
    v |= v >> 1
    v |= v >> 2
    v |= v >> 4
    v |= v >> 8
    v |= v >> 16
    v |= v >> 32
    return Int(bitPattern: v &+ 1)
}

func van_emde_boas_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { van_emde_boas_sort($0) }
}

func van_emde_boas_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count <= 1 {
        return
    }

    var min = a[0]
    var max = a[0]
    for i in 1..<a.count {
        if a[i] < min { min = a[i] }
        if a[i] > max { max = a[i] }
    }
    let span = max - min + 1
    var count = [Int](repeating: 0, count: span)

    for i in 0..<a.count {
        count[a[i] - min] += 1
    }

    let universe = Swift.max(next_power_of_two(span), 2)
    let tree = VebTree(universe: universe)

    for offset in 0..<count.count {
        if count[offset] > 0 {
            tree.insert(offset)
        }
    }

    var idx = 0
    var cur = tree.minimum()
    while let v = cur {
        let value = min + v
        for _ in 0..<count[v] {
            a[idx] = value
            idx += 1
        }
        cur = tree.successor(v)
    }
}
