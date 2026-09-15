final class SplayNode {
    var value: Int
    var count: Int
    var left: SplayNode?
    var right: SplayNode?

    init(value: Int, count: Int = 1, left: SplayNode? = nil, right: SplayNode? = nil) {
        self.value = value
        self.count = count
        self.left = left
        self.right = right
    }
}

func splay_rotate_right(_ x: SplayNode) -> SplayNode {
    let y = x.left!
    x.left = y.right
    y.right = x
    return y
}

func splay_rotate_left(_ x: SplayNode) -> SplayNode {
    let y = x.right!
    x.right = y.left
    y.left = x
    return y
}

func splay(_ root: SplayNode, _ key: Int) -> SplayNode {
    var root = root
    if key < root.value {
        if let leftTaken = root.left {
            var left = leftTaken
            root.left = nil
            if key < left.value {
                if let grand_left = left.left {
                    left.left = splay(grand_left, key)
                    left = splay_rotate_right(left)
                }
                root.left = left
                return splay_rotate_right(root)
            }
            if key > left.value {
                if let r = left.right {
                    left.right = splay(r, key)
                }
                if left.right != nil {
                    root.left = splay_rotate_left(left)
                    return splay_rotate_right(root)
                }
                root.left = left
            } else {
                // key == left.value: zig so the match becomes root (for count bumps).
                root.left = left
                return splay_rotate_right(root)
            }
        }
    } else if key > root.value {
        if let rightTaken = root.right {
            var right = rightTaken
            root.right = nil
            if key > right.value {
                if let grand_right = right.right {
                    right.right = splay(grand_right, key)
                    right = splay_rotate_left(right)
                }
                root.right = right
                return splay_rotate_left(root)
            }
            if key < right.value {
                if let l = right.left {
                    right.left = splay(l, key)
                }
                if right.left != nil {
                    root.right = splay_rotate_right(right)
                    return splay_rotate_left(root)
                }
                root.right = right
            } else {
                // key == right.value: zig so the match becomes root (for count bumps).
                root.right = right
                return splay_rotate_left(root)
            }
        }
    }
    return root
}

func splay_insert(_ root: SplayNode?, _ value: Int) -> SplayNode? {
    guard let node0 = root else {
        return SplayNode(value: value, count: 1)
    }
    var node = splay(node0, value)
    if node.value == value {
        node.count += 1
        return node
    }
    if value < node.value {
        let new_node = SplayNode(value: value, count: 1, left: node.left, right: nil)
        node.left = nil
        new_node.right = node
        return new_node
    } else {
        let right = node.right
        node.right = nil
        let new_node = SplayNode(value: value, count: 1, left: nil, right: right)
        new_node.left = node
        return new_node
    }
}

func drain_node(_ root: SplayNode?, _ out: inout [Int]) {
    guard let node = root else { return }
    drain_node(node.left, &out)
    for _ in 0..<node.count {
        out.append(node.value)
    }
    drain_node(node.right, &out)
}

func splay_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { splay_sort($0) }
}

func splay_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    var root: SplayNode? = nil
    for i in 0..<a.count {
        root = splay_insert(root, a[i])
    }
    var out = [Int]()
    out.reserveCapacity(a.count)
    drain_node(root, &out)
    for i in 0..<a.count {
        a[i] = out[i]
    }
}
