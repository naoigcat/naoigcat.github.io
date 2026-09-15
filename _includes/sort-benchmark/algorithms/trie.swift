final class TrieNode {
    var children: [TrieNode?] = Array(repeating: nil, count: 10)
    var terminal: [Int] = []
}

func max_digit_exp(_ max: Int) -> Int {
    var exp = 1
    while exp <= Int.max / 10 && exp * 10 <= max {
        exp *= 10
    }
    return exp
}

func trie_insert(_ node: TrieNode, _ value: Int, _ exp: Int) {
    if exp == 0 {
        node.terminal.append(value)
        return
    }
    let digit = (value / exp) % 10
    if node.children[digit] == nil {
        node.children[digit] = TrieNode()
    }
    trie_insert(node.children[digit]!, value, exp / 10)
}

func trie_collect(_ node: TrieNode, _ out: inout [Int]) {
    for child in node.children {
        if let child = child {
            trie_collect(child, &out)
        }
    }
    out.append(contentsOf: node.terminal)
}

func trie_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { trie_sort($0) }
}

func trie_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count == 0 {
        return
    }

    var max = a[0]
    for i in 1..<a.count {
        if a[i] > max {
            max = a[i]
        }
    }
    let exp = max_digit_exp(max)
    let root = TrieNode()

    for i in 0..<a.count {
        trie_insert(root, a[i], exp)
    }

    var out = [Int]()
    out.reserveCapacity(a.count)
    trie_collect(root, &out)
    for i in 0..<a.count {
        a[i] = out[i]
    }
}
