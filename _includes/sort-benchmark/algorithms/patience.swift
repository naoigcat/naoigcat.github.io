func patience_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { patience_sort($0) }
}

func patience_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    var piles: [[Int]] = []
    for i in 0..<a.count {
        let value = a[i]
        var lo = 0
        var hi = piles.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if piles[mid].last! >= value {
                hi = mid
            } else {
                lo = mid + 1
            }
        }
        if lo == piles.count {
            piles.append([value])
        } else {
            piles[lo].append(value)
        }
    }
    for slot in 0..<a.count {
        var min = 0
        for i in 1..<piles.count {
            if let pi = piles[i].last,
               piles[min].last.map({ pi < $0 }) ?? true
            {
                min = i
            }
        }
        a[slot] = piles[min].removeLast()
    }
}
