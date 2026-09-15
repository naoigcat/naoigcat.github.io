func merge_two_sorted(_ left: [Int], _ right: [Int]) -> [Int] {
    var out = [Int]()
    out.reserveCapacity(left.count + right.count)
    var i = 0
    var j = 0
    while i < left.count && j < right.count {
        if left[i] <= right[j] {
            out.append(left[i])
            i += 1
        } else {
            out.append(right[j])
            j += 1
        }
    }
    out.append(contentsOf: left[i...])
    out.append(contentsOf: right[j...])
    return out
}

func unshuffle_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { unshuffle_sort($0) }
}

func unshuffle_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    var piles = [[Int]]()

    for i in 0..<a.count {
        let x = a[i]
        var placed = false
        for p in 0..<piles.count {
            let front = piles[p][0]
            let back = piles[p].last!
            if x <= front {
                piles[p].insert(x, at: 0)
                placed = true
                break
            } else if x >= back {
                piles[p].append(x)
                placed = true
                break
            }
        }
        if !placed {
            piles.append([x])
        }
    }

    if piles.isEmpty {
        return
    }

    var merged = piles[0]
    for p in 1..<piles.count {
        merged = merge_two_sorted(merged, piles[p])
    }

    for i in 0..<a.count {
        a[i] = merged[i]
    }
}
