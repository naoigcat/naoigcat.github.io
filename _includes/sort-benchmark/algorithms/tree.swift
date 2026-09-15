final class TreeSortNode {
    var value: Int
    var count: Int
    var left: TreeSortNode?
    var right: TreeSortNode?

    init(value: Int, count: Int = 1, left: TreeSortNode? = nil, right: TreeSortNode? = nil) {
        self.value = value
        self.count = count
        self.left = left
        self.right = right
    }
}

func insert_node(_ root: inout TreeSortNode?, _ value: Int) {
    if let node = root {
        if value < node.value {
            insert_node(&node.left, value)
        } else if value > node.value {
            insert_node(&node.right, value)
        } else {
            node.count += 1
        }
    } else {
        root = TreeSortNode(value: value)
    }
}

func drain_node(_ root: TreeSortNode?, _ out: inout [Int]) {
    guard let node = root else { return }
    drain_node(node.left, &out)
    for _ in 0..<node.count {
        out.append(node.value)
    }
    drain_node(node.right, &out)
}

func tree_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { tree_sort($0) }
}

func tree_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    var root: TreeSortNode?
    for i in 0..<a.count {
        insert_node(&root, a[i])
    }
    var out = [Int]()
    out.reserveCapacity(a.count)
    drain_node(root, &out)
    for i in 0..<a.count {
        a[i] = out[i]
    }
}
