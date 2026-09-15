func proxmap_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { proxmap_sort($0) }
}

func proxmap_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.isEmpty {
        return
    }

    let n = a.count
    var min = a[0]
    var max = a[0]
    for i in 1..<n {
        if a[i] < min { min = a[i] }
        if a[i] > max { max = a[i] }
    }
    let bucket_count = n

    func map_key(_ x: Int) -> Int {
        if max == min {
            return 0
        } else {
            return ((x - min) * (bucket_count - 1)) / (max - min)
        }
    }

    var hit_count = [Int](repeating: 0, count: bucket_count)
    var map_keys = [Int]()
    map_keys.reserveCapacity(n)

    for i in 0..<n {
        let x = a[i]
        let mk = map_key(x)
        map_keys.append(mk)
        hit_count[mk] += 1
    }

    var prox_map = [Int?](repeating: nil, count: bucket_count)
    var running_total = 0

    for i in 0..<hit_count.count {
        let hits = hit_count[i]
        if hits > 0 {
            prox_map[i] = running_total
            running_total += hits
        }
    }

    let location: [Int] = map_keys.map { mk in
        prox_map[mk]!
    }

    var a2 = [Int?](repeating: nil, count: n)

    for i in 0..<n {
        let key = a[i]
        let start = location[i]
        var insert_idx = start

        while true {
            if a2[insert_idx] == nil {
                a2[insert_idx] = key
                break
            }

            let current = a2[insert_idx]!

            if key < current {
                var end = insert_idx + 1
                while end < n && a2[end] != nil {
                    end += 1
                }

                for k in (insert_idx..<end).reversed() {
                    a2[k + 1] = a2[k]
                }

                a2[insert_idx] = key
                break
            }

            insert_idx += 1
        }
    }

    for i in 0..<n {
        a[i] = a2[i]!
    }
}
