func iterative_quick_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { iterative_quick_sort($0) }
}

func iterative_quick_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count <= 1 {
        return
    }
    var stack = [(Int, Int)]()
    stack.reserveCapacity(64)
    stack.append((0, a.count - 1))
    while let (lo, hi) = stack.popLast() {
        if hi <= lo {
            continue
        }
        if hi - lo < 16 {
            insertion_sort(UnsafeMutableBufferPointer(rebasing: a[lo..<(hi + 1)]))
            continue
        }
        let p = partition(a, lo, hi)
        let leftOk = p > lo
        let rightOk = p < hi
        let leftLen = leftOk ? p - lo : 0
        let rightLen = rightOk ? hi - p : 0
        // Push the larger side first so the smaller side is processed next
        // and average stack depth stays O(log n).
        if leftLen > rightLen {
            if leftOk {
                stack.append((lo, p - 1))
            }
            if rightOk {
                stack.append((p + 1, hi))
            }
        } else {
            if rightOk {
                stack.append((p + 1, hi))
            }
            if leftOk {
                stack.append((lo, p - 1))
            }
        }
    }
}
