let LEONARDO: [Int] = [
    1, 1, 3, 5, 9, 15, 25, 41, 67, 109, 177, 287, 465, 753, 1219, 1973, 3193,
    5167, 8361, 13529, 21891, 35421, 57313, 92735, 150049, 242785, 392835,
    635621, 1028457, 1664079, 2692537, 4356617, 7049155, 11405773, 18454929,
    29860703, 48315633, 78176337, 126491971, 204668309, 331160281, 535828591,
    866988873, 1402817465, 2269806339, 3672623805,
]

func smooth_sift_in(_ a: UnsafeMutableBufferPointer<Int>, _ root_idx: Int, _ size: Int) {
    if size < 2 {
        return
    }
    let tmp = a[root_idx]
    var root = root_idx
    var sz = size
    while true {
        let right = root - 1
        let left = right - LEONARDO[sz - 2]
        let next: Int
        let next_size: Int
        if a[right] < a[left] {
            next = left
            next_size = sz - 1
        } else {
            next = right
            next_size = sz - 2
        }
        if a[next] <= tmp {
            break
        }
        a[root] = a[next]
        root = next
        sz = next_size
        if sz <= 1 {
            break
        }
    }
    a[root] = tmp
}

func smooth_interheap_sift(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ root_idx: Int,
    _ mask: Int,
    _ offset: Int
) {
    let tmp = a[root_idx]
    var root = root_idx
    var hmask = mask
    var hoffset = offset
    while hmask != 1 {
        var max = tmp
        if hoffset > 1 {
            let right = root - 1
            let left = right - LEONARDO[hoffset - 2]
            max = Swift.max(Swift.max(max, a[left]), a[right])
        }
        let next = root - LEONARDO[hoffset]
        if a[next] <= max {
            break
        }
        a[root] = a[next]
        root = next
        while true {
            hmask >>= 1
            hoffset += 1
            if hmask & 1 != 0 {
                break
            }
        }
    }
    a[root] = tmp
    smooth_sift_in(a, root, hoffset)
}

func smooth_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { smooth_sort($0) }
}

func smooth_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    var mask = 1
    var offset = 1
    for i in 1..<n {
        if mask & 2 != 0 {
            mask = (mask >> 2) | 1
            offset += 2
        } else if offset == 1 {
            mask = (mask << 1) | 1
            offset = 0
        } else {
            mask = (mask << (offset - 1)) | 1
            offset = 1
        }
        let wide_bottom =
            (mask & 2 != 0 && i + 1 < n)
            || (offset > 0 && 1 + i + LEONARDO[offset - 1] < n)
        if wide_bottom {
            smooth_sift_in(a, i, offset)
        } else {
            smooth_interheap_sift(a, i, mask, offset)
        }
    }
    for i in (2..<n).reversed() {
        if offset < 2 {
            while true {
                mask >>= 1
                offset += 1
                if mask & 1 != 0 {
                    break
                }
            }
        } else {
            let ch1 = i - 1
            let ch0 = ch1 - LEONARDO[offset - 2]
            mask &= ~1
            for ch in [ch0, ch1] {
                mask = (mask << 1) | 1
                offset -= 1
                smooth_interheap_sift(a, ch, mask, offset)
            }
        }
    }
}
