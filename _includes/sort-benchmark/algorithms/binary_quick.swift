func binary_quick_sort_bit(_ a: UnsafeMutableBufferPointer<Int>, _ bit: Int32) {
    let THRESHOLD = 16

    if a.count <= 1 || bit < 0 {
        return
    }
    if a.count <= THRESHOLD {
        insertion_sort(a)
        return
    }

    var i = 0
    var j = a.count
    while i < j {
        while i < j && ((a[i] >> bit) & 1) == 0 {
            i += 1
        }
        while i < j && ((a[j - 1] >> bit) & 1) == 1 {
            j -= 1
        }
        if i < j {
            a.swapAt(i, j - 1)
            i += 1
            j -= 1
        }
    }

    let mid = i
    binary_quick_sort_bit(UnsafeMutableBufferPointer(rebasing: a[0..<mid]), bit - 1)
    binary_quick_sort_bit(UnsafeMutableBufferPointer(rebasing: a[mid..<a.count]), bit - 1)
}

func binary_quick_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { binary_quick_sort($0) }
}

func binary_quick_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count <= 1 {
        return
    }
    let max = a.max()!
    let bit: Int32
    if max == 0 {
        bit = 0
    } else {
        bit = Int32(Int.bitWidth - 1 - max.leadingZeroBitCount)
    }
    binary_quick_sort_bit(a, bit)
}
