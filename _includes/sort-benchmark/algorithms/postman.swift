fileprivate func postman_sort_bytes(_ a: UnsafeMutableBufferPointer<Int>, _ byte: Int) {
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
    var buckets = [[Int]](repeating: [], count: W)

    for i in 0..<a.count {
        let value = a[i]
        let digit = (value >> shift) & 0xFF
        buckets[digit].append(value)
    }

    var offset = 0
    for b in 0..<W {
        if buckets[b].count > 1 {
            buckets[b].withUnsafeMutableBufferPointer { postman_sort_bytes($0, byte + 1) }
        }
        let len = buckets[b].count
        if len > 0 {
            for i in 0..<len {
                a[offset + i] = buckets[b][i]
            }
            offset += len
        }
    }
}

func postman_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { postman_sort($0) }
}

func postman_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if !a.isEmpty {
        postman_sort_bytes(a, 0)
    }
}
