private let CRADIX_RADIX = 10
private let CRADIX_BS = 2

private func cradix_digit_width(_ max: Int) -> Int {
    if max == 0 {
        return 1
    }
    var w = 0
    var v = max
    while v > 0 {
        w += 1
        v /= CRADIX_RADIX
    }
    return w
}

private func cradix_digit_at(_ value: Int, _ pos: Int, _ width: Int) -> UInt8 {
    let power = width - 1 - pos
    var div = 1
    for _ in 0..<power {
        if div > Int.max / CRADIX_RADIX {
            div = Int.max
            break
        }
        div *= CRADIX_RADIX
    }
    return UInt8((value / div) % CRADIX_RADIX)
}

private func cradix_fill_buffer(_ value: Int, _ start: Int, _ width: Int) -> [UInt8] {
    var buf = [UInt8](repeating: 0, count: CRADIX_BS)
    for i in 0..<CRADIX_BS {
        if start + i < width {
            buf[i] = cradix_digit_at(value, start + i, width)
        }
    }
    return buf
}

private func cradix_rec(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ buffers: inout [[UInt8]],
    _ digit_pos: Int,
    _ width: Int
) {
    let n = a.count
    if n <= 1 || digit_pos >= width {
        return
    }

    var count = [Int](repeating: 0, count: CRADIX_RADIX)
    for b in buffers {
        count[Int(b[0])] += 1
    }

    var offset = [Int](repeating: 0, count: CRADIX_RADIX)
    for i in 1..<CRADIX_RADIX {
        offset[i] = offset[i - 1] + count[i - 1]
    }

    var out_a = [Int](repeating: 0, count: n)
    var out_b = [[UInt8]](repeating: [UInt8](repeating: 0, count: CRADIX_BS), count: n)
    var cursor = offset
    for i in 0..<n {
        let d = Int(buffers[i][0])
        out_a[cursor[d]] = a[i]
        out_b[cursor[d]] = buffers[i]
        cursor[d] += 1
    }
    for i in 0..<n {
        a[i] = out_a[i]
    }
    buffers = out_b

    for r in 0..<CRADIX_RADIX {
        let start = offset[r]
        let len = count[r]
        if len <= 1 {
            continue
        }
        let next_pos = digit_pos + 1
        if next_pos >= width {
            continue
        }

        let end = start + len
        for i in start..<end {
            for j in 0..<(CRADIX_BS - 1) {
                buffers[i][j] = buffers[i][j + 1]
            }
            buffers[i][CRADIX_BS - 1] = 0
        }

        if next_pos % CRADIX_BS == 0 {
            for i in start..<end {
                buffers[i] = cradix_fill_buffer(a[i], next_pos, width)
            }
        }

        var subBuffers = Array(buffers[start..<end])
        cradix_rec(
            UnsafeMutableBufferPointer(rebasing: a[start..<end]),
            &subBuffers,
            next_pos,
            width
        )
        for i in 0..<len {
            buffers[start + i] = subBuffers[i]
        }
    }
}

func cradix_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { cradix_sort($0) }
}

func cradix_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.isEmpty {
        return
    }

    var max = a[0]
    for i in 1..<a.count {
        if a[i] > max { max = a[i] }
    }
    let width = cradix_digit_width(max)
    let n = a.count
    var buffers = [[UInt8]](repeating: [UInt8](repeating: 0, count: CRADIX_BS), count: n)
    for i in 0..<n {
        buffers[i] = cradix_fill_buffer(a[i], 0, width)
    }
    cradix_rec(a, &buffers, 0, width)
}
