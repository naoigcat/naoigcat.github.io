func merge_values(_ left: UnsafeBufferPointer<Int>, _ right: UnsafeBufferPointer<Int>) -> [Int] {
    var out = [Int]()
    out.reserveCapacity(left.count + right.count)
    var l = 0
    var r = 0
    while l < left.count && r < right.count {
        if left[l] <= right[r] {
            out.append(left[l])
            l += 1
        } else {
            out.append(right[r])
            r += 1
        }
    }
    while l < left.count {
        out.append(left[l])
        l += 1
    }
    while r < right.count {
        out.append(right[r])
        r += 1
    }
    return out
}

func merge_values(_ left: [Int], _ right: [Int]) -> [Int] {
    left.withUnsafeBufferPointer { leftBuf in
        right.withUnsafeBufferPointer { rightBuf in
            merge_values(leftBuf, rightBuf)
        }
    }
}
