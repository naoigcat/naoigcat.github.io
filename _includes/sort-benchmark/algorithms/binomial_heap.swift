final class BinomialNode {
    var key: Int
    var degree: UInt32
    var child: BinomialNode?
    var sibling: BinomialNode?

    init(key: Int, degree: UInt32 = 0, child: BinomialNode? = nil, sibling: BinomialNode? = nil) {
        self.key = key
        self.degree = degree
        self.child = child
        self.sibling = sibling
    }
}

func link(_ child: BinomialNode, _ parent: BinomialNode) -> BinomialNode {
    child.sibling = parent.child
    parent.child = child
    parent.degree += 1
    return parent
}

func roots_to_vec(_ head: BinomialNode?) -> [BinomialNode] {
    var head = head
    var roots = [BinomialNode]()
    while let node = head {
        head = node.sibling
        node.sibling = nil
        roots.append(node)
    }
    return roots
}

func vec_to_roots(_ roots: [BinomialNode]) -> BinomialNode? {
    var head: BinomialNode? = nil
    var tail: BinomialNode? = nil
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

func merge_root_lists(_ a: BinomialNode?, _ b: BinomialNode?) -> BinomialNode? {
    var a = a
    var b = b
    var merged = [BinomialNode]()
    while let aNode = a, let bNode = b {
        if aNode.degree <= bNode.degree {
            a = aNode.sibling
            aNode.sibling = nil
            merged.append(aNode)
        } else {
            b = bNode.sibling
            bNode.sibling = nil
            merged.append(bNode)
        }
    }
    while let node = a {
        a = node.sibling
        node.sibling = nil
        merged.append(node)
    }
    while let node = b {
        b = node.sibling
        node.sibling = nil
        merged.append(node)
    }
    return vec_to_roots(merged)
}

func consolidate(_ head: BinomialNode?) -> BinomialNode? {
    var roots = roots_to_vec(head)
    var i = 0
    while i + 1 < roots.count {
        if roots[i].degree != roots[i + 1].degree {
            i += 1
            continue
        }
        // Three equal degrees: leave the first and merge the latter two (CLRS).
        if i + 2 < roots.count && roots[i + 2].degree == roots[i].degree {
            i += 1
            continue
        }
        let a = roots.remove(at: i)
        let b = roots.remove(at: i)
        let linked: BinomialNode
        if a.key <= b.key {
            linked = link(b, a)
        } else {
            linked = link(a, b)
        }
        roots.insert(linked, at: i)
    }
    return vec_to_roots(roots)
}

func union(_ h1: BinomialNode?, _ h2: BinomialNode?) -> BinomialNode? {
    consolidate(merge_root_lists(h1, h2))
}

func insert_key(_ heap: BinomialNode?, _ key: Int) -> BinomialNode? {
    let node = BinomialNode(key: key)
    return union(heap, node)
}

func reverse_children(_ child: BinomialNode?) -> BinomialNode? {
    var child = child
    var rev: BinomialNode? = nil
    while let node = child {
        child = node.sibling
        node.sibling = rev
        rev = node
    }
    return rev
}

func extract_min(_ heap: BinomialNode?) -> (Int?, BinomialNode?) {
    guard let head = heap else {
        return (nil, nil)
    }

    var roots = roots_to_vec(head)
    var min_i = 0
    for i in 1..<roots.count {
        if roots[i].key < roots[min_i].key {
            min_i = i
        }
    }

    let min_node = roots.remove(at: min_i)
    let key = min_node.key
    let children = reverse_children(min_node.child)
    min_node.child = nil
    return (key, union(vec_to_roots(roots), children))
}

func binomial_heap_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { binomial_heap_sort($0) }
}

func binomial_heap_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    var heap: BinomialNode? = nil
    for i in 0..<a.count {
        heap = insert_key(heap, a[i])
    }
    for i in 0..<a.count {
        let (key, next) = extract_min(heap)
        heap = next
        guard let key else {
            fatalError("binomial heap exhausted early")
        }
        a[i] = key
    }
}
