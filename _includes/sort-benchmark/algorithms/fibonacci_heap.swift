final class FibNode {
    var key: Int
    var degree: UInt32
    var child: FibNode?
    var sibling: FibNode?

    init(key: Int, degree: UInt32 = 0, child: FibNode? = nil, sibling: FibNode? = nil) {
        self.key = key
        self.degree = degree
        self.child = child
        self.sibling = sibling
    }
}

private func fib_link(_ child: FibNode, _ parent: FibNode) -> FibNode {
    child.sibling = parent.child
    parent.child = child
    parent.degree += 1
    return parent
}

private func fib_roots_to_vec(_ head: FibNode?) -> [FibNode] {
    var head = head
    var roots = [FibNode]()
    while let node = head {
        head = node.sibling
        node.sibling = nil
        roots.append(node)
    }
    return roots
}

private func fib_vec_to_roots(_ roots: [FibNode]) -> FibNode? {
    var head: FibNode? = nil
    var tail: FibNode? = nil
    for node in roots {
        node.sibling = nil
        if head == nil {
            head = node
            tail = node
        } else {
            tail!.sibling = node
            tail = node
        }
    }
    return head
}

private func fib_consolidate(_ head: FibNode?) -> FibNode? {
    let roots = fib_roots_to_vec(head)
    if roots.isEmpty {
        return nil
    }

    var degree_table = [FibNode?]()

    for rootNode in roots {
        var x = rootNode
        while true {
            let d = Int(x.degree)
            while d >= degree_table.count {
                degree_table.append(nil)
            }
            if degree_table[d] == nil {
                degree_table[d] = x
                break
            }
            let y = degree_table[d]!
            degree_table[d] = nil
            if x.key <= y.key {
                x = fib_link(y, x)
            } else {
                x = fib_link(x, y)
            }
        }
    }

    var new_roots = [FibNode]()
    for slot in degree_table {
        if let node = slot {
            new_roots.append(node)
        }
    }
    return fib_vec_to_roots(new_roots)
}

private func fib_insert_key(_ heap: FibNode?, _ key: Int) -> FibNode? {
    let node = FibNode(key: key)
    node.sibling = heap
    return node
}

private func fib_extract_min(_ heap: FibNode?) -> (Int?, FibNode?) {
    guard let head = heap else {
        return (nil, nil)
    }

    var roots = fib_roots_to_vec(head)
    var min_i = 0
    for i in 1..<roots.count {
        if roots[i].key < roots[min_i].key {
            min_i = i
        }
    }

    let min_node = roots.remove(at: min_i)
    let key = min_node.key
    let children = fib_roots_to_vec(min_node.child)
    min_node.child = nil
    roots.append(contentsOf: children)
    return (key, fib_consolidate(fib_vec_to_roots(roots)))
}

func fibonacci_heap_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { fibonacci_heap_sort($0) }
}

func fibonacci_heap_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    var heap: FibNode? = nil
    for i in 0..<a.count {
        heap = fib_insert_key(heap, a[i])
    }
    for i in 0..<a.count {
        let (key, next) = fib_extract_min(heap)
        heap = next
        guard let key else {
            fatalError("fibonacci heap exhausted early")
        }
        a[i] = key
    }
}
