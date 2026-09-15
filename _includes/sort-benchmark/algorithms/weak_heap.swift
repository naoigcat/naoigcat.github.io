func get_flag(_ r: [UInt8], _ x: Int) -> Int {
    Int((r[x >> 3] >> (x & 7)) & 1)
}

func toggle_flag(_ r: inout [UInt8], _ x: Int) {
    r[x >> 3] ^= 1 << (x & 7)
}

/// Join two equal-height weak heaps rooted at `i` (distinguished ancestor) and `j`.
/// Max-heap form: if `a[j]` is larger, promote it and flip the reverse bit at `j`.
func join(_ a: UnsafeMutableBufferPointer<Int>, _ r: inout [UInt8], _ i: Int, _ j: Int) {
    if a[i] < a[j] {
        toggle_flag(&r, j)
        a.swapAt(i, j)
    }
}

func distinguished_ancestor(_ r: [UInt8], _ j: Int) -> Int {
    var j = j
    while (j & 1) == get_flag(r, j >> 1) {
        j >>= 1
    }
    return j >> 1
}

func weak_heap_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { weak_heap_sort($0) }
}

func weak_heap_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }

    var r = [UInt8](repeating: 0, count: (n + 7) / 8)

    // Bottom-up construct: n - 1 joins with each node's distinguished ancestor.
    for i in (1..<n).reversed() {
        let g = distinguished_ancestor(r, i)
        join(a, &r, g, i)
    }

    // Extract maxima like heapsort; sift-down uses left-spine + upward joins.
    for end in (2..<n).reversed() {
        a.swapAt(0, end)
        var x = 1
        while true {
            let y = 2 * x + get_flag(r, x)
            if y >= end {
                break
            }
            x = 2 * x + get_flag(r, x)
        }
        while x > 0 {
            join(a, &r, 0, x)
            x >>= 1
        }
    }
    a.swapAt(0, 1)
}
