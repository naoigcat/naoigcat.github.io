func american_flag_sort_bytes(_ a: UnsafeMutableBufferPointer<Int>, _ byte: Int) {
    let W = 256
    let THRESHOLD = 16

    if a.count <= THRESHOLD {
        insertion_sort(a)
        return
    }
    if byte >= MemoryLayout<Int>.size {
        return
    }

    let shift = (MemoryLayout<Int>.size - 1 - byte) * 8

    var count = Array(repeating: 0, count: W)
    for i in 0..<a.count {
        count[(a[i] >> shift) & 0xFF] += 1
    }

    var begin = Array(repeating: 0, count: W)
    var sum = 0
    for i in 0..<W {
        begin[i] = sum
        sum += count[i]
    }

    let initial = begin
    var end = Array(repeating: 0, count: W)
    for i in 0..<W {
        end[i] = begin[i] + count[i]
    }

    for bucket in 0..<W {
        if count[bucket] == 0 {
            continue
        }

        while begin[bucket] < end[bucket] {
            let digit = (a[begin[bucket]] >> shift) & 0xFF
            if digit != bucket {
                end[digit] -= 1
                a.swapAt(begin[bucket], end[digit])
            } else {
                begin[bucket] += 1
            }
        }

        let start = initial[bucket]
        if count[bucket] > 1 {
            american_flag_sort_bytes(
                UnsafeMutableBufferPointer(rebasing: a[start..<(start + count[bucket])]),
                byte + 1
            )
        }
    }
}

func american_flag_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { american_flag_sort($0) }
}

func american_flag_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if !a.isEmpty {
        american_flag_sort_bytes(a, 0)
    }
}
