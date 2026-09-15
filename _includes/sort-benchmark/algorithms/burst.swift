final class BurstNode {
    var children: [BurstNode?] = Array(repeating: nil, count: 10)
    var bucket: [Int] = []

    var is_trie: Bool {
        children.contains { $0 != nil }
    }
}

let BURST_THRESHOLD = 16

func max_digit_exp(_ max: Int) -> Int {
    var exp = 1
    while exp <= Int.max / 10 && exp * 10 <= max {
        exp *= 10
    }
    return exp
}

func burst_insert(_ node: BurstNode, _ value: Int, _ exp: Int) {
    if node.is_trie {
        if exp == 0 {
            node.bucket.append(value)
            return
        }
        let digit = (value / exp) % 10
        if node.children[digit] == nil {
            node.children[digit] = BurstNode()
        }
        burst_insert(node.children[digit]!, value, exp / 10)
        return
    }

    node.bucket.append(value)
    if node.bucket.count > BURST_THRESHOLD && exp > 0 {
        let exp_now = exp
        let items = node.bucket
        node.bucket = []
        for v in items {
            let digit = (v / exp_now) % 10
            if node.children[digit] == nil {
                node.children[digit] = BurstNode()
            }
            burst_insert(node.children[digit]!, v, exp_now / 10)
        }
    }
}

func burst_collect(_ node: BurstNode, _ out: inout [Int]) {
    if node.is_trie {
        for child in node.children {
            if let child {
                burst_collect(child, &out)
            }
        }
    }
    if !node.bucket.isEmpty {
        var bucket = node.bucket
        insertion_sort(&bucket)
        out.append(contentsOf: bucket)
    }
}

func burst_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { burst_sort($0) }
}

func burst_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.isEmpty {
        return
    }

    let max = a.max()!
    let exp = max_digit_exp(max)
    let root = BurstNode()

    for i in 0..<a.count {
        burst_insert(root, a[i], exp)
    }

    var out = [Int]()
    out.reserveCapacity(a.count)
    burst_collect(root, &out)
    for i in 0..<a.count {
        a[i] = out[i]
    }
}
