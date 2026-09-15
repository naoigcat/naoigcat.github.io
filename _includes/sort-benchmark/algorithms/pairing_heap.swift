fileprivate final class PairingNode {
    var key: Int
    var child: PairingNode?
    var sibling: PairingNode?

    init(key: Int, child: PairingNode? = nil, sibling: PairingNode? = nil) {
        self.key = key
        self.child = child
        self.sibling = sibling
    }
}

fileprivate func pairing_meld(_ a: PairingNode?, _ b: PairingNode?) -> PairingNode? {
    guard let a else { return b }
    guard let b else { return a }
    if a.key <= b.key {
        b.sibling = a.child
        a.child = b
        return a
    } else {
        a.sibling = b.child
        b.child = a
        return b
    }
}

fileprivate func pairing_two_pass_meld(_ first: PairingNode?) -> PairingNode? {
    var first = first
    var pairs = [PairingNode?]()
    while let a = first {
        first = a.sibling
        a.sibling = nil
        if let b = first {
            first = b.sibling
            b.sibling = nil
            pairs.append(pairing_meld(a, b))
        } else {
            pairs.append(a)
        }
    }

    var result: PairingNode? = nil
    for pair in pairs.reversed() {
        result = pairing_meld(pair, result)
    }
    return result
}

fileprivate func pairing_insert_key(_ heap: PairingNode?, _ key: Int) -> PairingNode? {
    let node = PairingNode(key: key)
    return pairing_meld(heap, node)
}

fileprivate func pairing_extract_min(_ heap: PairingNode?) -> (Int?, PairingNode?) {
    guard let root = heap else {
        return (nil, nil)
    }
    let key = root.key
    let children = root.child
    root.child = nil
    return (key, pairing_two_pass_meld(children))
}

func pairing_heap_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { pairing_heap_sort($0) }
}

func pairing_heap_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    var heap: PairingNode? = nil
    for i in 0..<a.count {
        heap = pairing_insert_key(heap, a[i])
    }
    for i in 0..<a.count {
        let (key, next) = pairing_extract_min(heap)
        heap = next
        guard let key else {
            fatalError("pairing heap exhausted early")
        }
        a[i] = key
    }
}
