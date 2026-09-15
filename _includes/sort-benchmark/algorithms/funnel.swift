private func funnel_cbrt_ceil(_ n: Int) -> Int {
    if n <= 1 {
        return n
    }
    var x = Int(cbrt(Double(n)).rounded(.up))
    if x < 2 {
        x = 2
    }
    while x * x * x < n {
        x += 1
    }
    return x
}

private func funnel_next_pow2(_ x: Int) -> Int {
    var x = x
    if x <= 2 {
        return 2
    }
    x -= 1
    x |= x >> 1
    x |= x >> 2
    x |= x >> 4
    x |= x >> 8
    x |= x >> 16
    x |= x >> 32
    return x + 1
}

private func funnel_buffer_cap(_ leaves: Int) -> Int {
    if leaves <= 1 {
        return 2
    }
    let k = Double(leaves)
    return max(Int((k * k.squareRoot()).rounded(.up)), 2)
}

private final class FunnelNode {
    var buf: [Int]
    var head: Int
    var cap: Int
    var run: (Int, Int)?
    var pos: Int
    var left: Int?
    var right: Int?
    var exhausted: Bool

    static func leaf(_ lo: Int, _ hi: Int) -> FunnelNode {
        FunnelNode(
            buf: [],
            head: 0,
            cap: 0,
            run: (lo, hi),
            pos: lo,
            left: nil,
            right: nil,
            exhausted: lo >= hi
        )
    }

    static func internalNode(_ cap: Int, _ left: Int, _ right: Int) -> FunnelNode {
        FunnelNode(
            buf: [],
            head: 0,
            cap: cap,
            run: nil,
            pos: 0,
            left: left,
            right: right,
            exhausted: false
        )
    }

    private init(
        buf: [Int],
        head: Int,
        cap: Int,
        run: (Int, Int)?,
        pos: Int,
        left: Int?,
        right: Int?,
        exhausted: Bool
    ) {
        self.buf = buf
        self.head = head
        self.cap = cap
        self.run = run
        self.pos = pos
        self.left = left
        self.right = right
        self.exhausted = exhausted
        if cap > 0 {
            self.buf.reserveCapacity(cap)
        }
    }

    func buf_len() -> Int {
        max(buf.count - head, 0)
    }

    func buf_clear_consumed() {
        if head > 0 {
            buf.removeFirst(head)
            head = 0
        }
    }

    func buf_push(_ v: Int) {
        buf_clear_consumed()
        buf.append(v)
    }

    func buf_peek() -> Int? {
        if head < buf.count {
            return buf[head]
        }
        return nil
    }

    func buf_pop() -> Int? {
        if head >= buf.count {
            return nil
        }
        let v = buf[head]
        head += 1
        if head == buf.count {
            buf.removeAll(keepingCapacity: true)
            head = 0
        }
        return v
    }
}

private func funnel_build_tree(_ k: Int, _ runs: [(Int, Int)]) -> ([FunnelNode], Int) {
    var nodes = [FunnelNode]()
    nodes.reserveCapacity(2 * k)
    for i in 0..<k {
        if i < runs.count {
            nodes.append(FunnelNode.leaf(runs[i].0, runs[i].1))
        } else {
            nodes.append(FunnelNode.leaf(0, 0))
        }
    }
    var layer = Array(0..<k)
    var leaves_per = [Int](repeating: 1, count: k)
    while layer.count > 1 {
        var next_layer = [Int]()
        var next_leaves = [Int]()
        var i = 0
        while i < layer.count {
            if i + 1 < layer.count {
                let left = layer[i]
                let right = layer[i + 1]
                let leaves = leaves_per[i] + leaves_per[i + 1]
                let parent = nodes.count
                nodes.append(FunnelNode.internalNode(funnel_buffer_cap(leaves), left, right))
                next_layer.append(parent)
                next_leaves.append(leaves)
                i += 2
            } else {
                next_layer.append(layer[i])
                next_leaves.append(leaves_per[i])
                i += 1
            }
        }
        layer = next_layer
        leaves_per = next_leaves
    }
    let root = layer[0]
    if nodes[root].run == nil {
        let total_leaves = max(runs.count, 1)
        let want = Int(pow(Double(total_leaves), 3).rounded(.up))
        nodes[root].cap = max(max(nodes[root].cap, want), 2)
        nodes[root].buf.reserveCapacity(nodes[root].cap)
    }
    return (nodes, root)
}

private func funnel_leaf_has(_ nodes: [FunnelNode], _ leaf: Int) -> Bool {
    if nodes[leaf].exhausted {
        return false
    }
    guard let (_, hi) = nodes[leaf].run else {
        return false
    }
    return nodes[leaf].pos < hi
}

private func funnel_leaf_peek(
    _ nodes: [FunnelNode],
    _ leaf: Int,
    _ a: UnsafeMutableBufferPointer<Int>
) -> Int? {
    if !funnel_leaf_has(nodes, leaf) {
        return nil
    }
    return a[nodes[leaf].pos]
}

private func funnel_leaf_pop(
    _ nodes: inout [FunnelNode],
    _ leaf: Int,
    _ a: UnsafeMutableBufferPointer<Int>
) -> Int? {
    guard let v = funnel_leaf_peek(nodes, leaf, a) else {
        return nil
    }
    nodes[leaf].pos += 1
    if let (_, hi) = nodes[leaf].run {
        if nodes[leaf].pos >= hi {
            nodes[leaf].exhausted = true
        }
    }
    return v
}

private func funnel_fill(
    _ nodes: inout [FunnelNode],
    _ idx: Int,
    _ a: UnsafeMutableBufferPointer<Int>
) {
    if nodes[idx].run != nil || nodes[idx].exhausted {
        return
    }
    let cap = nodes[idx].cap
    while nodes[idx].buf_len() < cap {
        guard let left = nodes[idx].left, let right = nodes[idx].right else {
            fatalError("internal")
        }

        if nodes[left].run == nil && nodes[left].buf_len() == 0 && !nodes[left].exhausted {
            funnel_fill(&nodes, left, a)
        }
        if nodes[right].run == nil && nodes[right].buf_len() == 0 && !nodes[right].exhausted {
            funnel_fill(&nodes, right, a)
        }

        let left_ok: Bool
        if nodes[left].run != nil {
            left_ok = funnel_leaf_has(nodes, left)
        } else {
            left_ok = nodes[left].buf_len() > 0
        }
        let right_ok: Bool
        if nodes[right].run != nil {
            right_ok = funnel_leaf_has(nodes, right)
        } else {
            right_ok = nodes[right].buf_len() > 0
        }

        if !left_ok && !right_ok {
            nodes[idx].exhausted = true
            break
        }

        let take_left: Bool
        if left_ok && right_ok {
            let lv: Int
            if nodes[left].run != nil {
                lv = funnel_leaf_peek(nodes, left, a)!
            } else {
                lv = nodes[left].buf_peek()!
            }
            let rv: Int
            if nodes[right].run != nil {
                rv = funnel_leaf_peek(nodes, right, a)!
            } else {
                rv = nodes[right].buf_peek()!
            }
            take_left = lv <= rv
        } else {
            take_left = left_ok
        }

        let v: Int
        if take_left {
            if nodes[left].run != nil {
                v = funnel_leaf_pop(&nodes, left, a)!
            } else {
                v = nodes[left].buf_pop()!
            }
        } else if nodes[right].run != nil {
            v = funnel_leaf_pop(&nodes, right, a)!
        } else {
            v = nodes[right].buf_pop()!
        }
        nodes[idx].buf_push(v)
    }
}

private func funnel_merge_runs(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ runs: [(Int, Int)],
    _ k: Int
) {
    if runs.count <= 1 {
        return
    }
    var (nodes, root) = funnel_build_tree(k, runs)
    let total = runs.reduce(0) { $0 + ($1.1 - $1.0) }
    var out = [Int]()
    out.reserveCapacity(total)
    while out.count < total {
        funnel_fill(&nodes, root, a)
        if nodes[root].buf_len() == 0 {
            break
        }
        let head = nodes[root].head
        out.append(contentsOf: nodes[root].buf[head...])
        nodes[root].buf.removeAll(keepingCapacity: true)
        nodes[root].head = 0
        if nodes[root].exhausted {
            break
        }
    }
    let base = runs[0].0
    for i in 0..<total {
        a[base + i] = out[i]
    }
}

func funnel_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { funnel_sort($0) }
}

func funnel_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 8 {
        insertion_sort(a)
        return
    }
    var k = funnel_next_pow2(funnel_cbrt_ceil(n))
    while k > n {
        k /= 2
    }
    k = max(k, 2)

    let block = (n + k - 1) / k
    var runs = [(Int, Int)]()
    runs.reserveCapacity(k)
    var i = 0
    while i < n {
        let end = min(i + block, n)
        funnel_sort(UnsafeMutableBufferPointer(rebasing: a[i..<end]))
        if end > i {
            runs.append((i, end))
        }
        i = end
    }
    let merge_k = funnel_next_pow2(max(runs.count, 2))
    funnel_merge_runs(a, runs, merge_k)
}
