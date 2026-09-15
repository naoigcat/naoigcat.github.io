fileprivate func multi_key_digit(_ value: Int, _ byte: Int) -> Int {
    let width = MemoryLayout<Int>.size
    if byte >= width {
        return 0
    }
    let shift = (width - 1 - byte) * 8
    // `Int` `>>` is arithmetic
    return Int((UInt(bitPattern: value) >> UInt(shift)) & 0xFF)
}

fileprivate func multi_key_quick_sort_range(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ lo: Int,
    _ hi: Int,
    _ byte: Int
) {
    let THRESHOLD = 16
    let WIDTH = MemoryLayout<Int>.size

    if hi <= lo {
        return
    }
    if hi - lo < THRESHOLD {
        insertion_sort(UnsafeMutableBufferPointer(rebasing: a[lo..<(hi + 1)]))
        return
    }
    if byte >= WIDTH {
        return
    }

    let pivot = multi_key_digit(a[lo], byte)
    var lt = lo
    var i = lo + 1
    var gt = hi

    while i <= gt {
        let d = multi_key_digit(a[i], byte)
        if d < pivot {
            a.swapAt(lt, i)
            lt += 1
            i += 1
        } else if d > pivot {
            a.swapAt(i, gt)
            gt -= 1
        } else {
            i += 1
        }
    }

    if lt > lo {
        multi_key_quick_sort_range(a, lo, lt - 1, byte)
    }
    if gt >= lt {
        multi_key_quick_sort_range(a, lt, gt, byte + 1)
    }
    if gt < hi {
        multi_key_quick_sort_range(a, gt + 1, hi, byte)
    }
}

func multi_key_quick_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { multi_key_quick_sort($0) }
}

func multi_key_quick_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count > 0 {
        let hi = a.count - 1
        multi_key_quick_sort_range(a, 0, hi, 0)
    }
}
