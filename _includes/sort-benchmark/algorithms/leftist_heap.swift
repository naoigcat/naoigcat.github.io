fileprivate final class LeftistNode {
    var key: Int
    var npl: Int32
    var left: LeftistNode?
    var right: LeftistNode?

    init(key: Int, npl: Int32 = 0, left: LeftistNode? = nil, right: LeftistNode? = nil) {
        self.key = key
        self.npl = npl
        self.left = left
        self.right = right
    }
}

fileprivate func leftist_npl(_ node: LeftistNode?) -> Int32 {
    node?.npl ?? -1
}

fileprivate func leftist_merge(_ a: LeftistNode?, _ b: LeftistNode?) -> LeftistNode? {
    guard let a else { return b }
    guard let b else { return a }
    var x = a
    var y = b
    if x.key > y.key {
        swap(&x, &y)
    }
    let oldRight = x.right
    x.right = nil
    x.right = leftist_merge(oldRight, y)
    if leftist_npl(x.left) < leftist_npl(x.right) {
        swap(&x.left, &x.right)
    }
    x.npl = leftist_npl(x.right) + 1
    return x
}

fileprivate func leftist_insert_key(_ heap: LeftistNode?, _ key: Int) -> LeftistNode? {
    let node = LeftistNode(key: key)
    return leftist_merge(heap, node)
}

fileprivate func leftist_extract_min(_ heap: LeftistNode?) -> (Int?, LeftistNode?) {
    guard let root = heap else {
        return (nil, nil)
    }
    let key = root.key
    let left = root.left
    let right = root.right
    root.left = nil
    root.right = nil
    return (key, leftist_merge(left, right))
}

func leftist_heap_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { leftist_heap_sort($0) }
}

func leftist_heap_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    var heap: LeftistNode? = nil
    for i in 0..<a.count {
        heap = leftist_insert_key(heap, a[i])
    }
    for i in 0..<a.count {
        let (key, next) = leftist_extract_min(heap)
        heap = next
        guard let key else {
            fatalError("leftist heap exhausted early")
        }
        a[i] = key
    }
}
