func circle_pass(_ a: UnsafeMutableBufferPointer<Int>, _ low: Int, _ high: Int) -> Bool {
    if low >= high {
        return false
    }

    var swapped = false
    var left = low
    var right = high

    while left < right {
        if a[left] > a[right] {
            a.swapAt(left, right)
            swapped = true
        }
        left += 1
        right -= 1
    }

    // Odd-length range: compare the middle element with its right neighbor.
    if left == right && right + 1 <= high && a[left] > a[right + 1] {
        a.swapAt(left, right + 1)
        swapped = true
    }

    let mid = low + (high - low) / 2
    let left_swapped = circle_pass(a, low, mid)
    let right_swapped = circle_pass(a, mid + 1, high)
    return swapped || left_swapped || right_swapped
}

func circle_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { circle_sort($0) }
}

func circle_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n < 2 {
        return
    }
    while circle_pass(a, 0, n - 1) {}
}
