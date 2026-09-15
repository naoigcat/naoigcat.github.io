func cartesian_tree_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { cartesian_tree_sort($0) }
}

func cartesian_tree_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    var left = Array<Int?>(repeating: nil, count: n)
    var right = Array<Int?>(repeating: nil, count: n)
    var stack = [Int]()
    for i in 0..<n {
        var last: Int? = nil
        while let top = stack.last, a[top] > a[i] {
            last = stack.removeLast()
        }
        if let top = stack.last {
            right[top] = i
        }
        if let last_idx = last {
            left[i] = last_idx
        }
        stack.append(i)
    }

    func extract(
        _ node: Int?,
        _ a: UnsafeMutableBufferPointer<Int>,
        _ left: [Int?],
        _ right: [Int?]
    ) -> [Int] {
        guard let i = node else {
            return []
        }
        let l = extract(left[i], a, left, right)
        let r = extract(right[i], a, left, right)
        let merged = merge_values(l, r)
        var out = [Int]()
        out.reserveCapacity(merged.count + 1)
        out.append(a[i])
        out.append(contentsOf: merged)
        return out
    }

    let root = stack.first
    let out = extract(root, a, left, right)
    for i in 0..<n {
        a[i] = out[i]
    }
}
