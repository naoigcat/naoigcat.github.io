func shear_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { shear_sort($0) }
}

func shear_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }
    let side = Int((Double(n)).squareRoot().rounded(.up))
    var grid = [Int](repeating: Int.max, count: side * side)
    for i in 0..<n {
        grid[i] = a[i]
    }
    let phases = (Int(log2(Double(side)).rounded(.up)) + 1) * 2
    for _ in 0..<phases {
        for r in 0..<side {
            var row = Array(grid[(r * side)..<((r + 1) * side)])
            insertion_sort(&row)
            if r % 2 == 1 {
                row.reverse()
            }
            for c in 0..<side {
                grid[r * side + c] = row[c]
            }
        }
        for c in 0..<side {
            var col = [Int]()
            col.reserveCapacity(side)
            for r in 0..<side {
                col.append(grid[r * side + c])
            }
            insertion_sort(&col)
            for r in 0..<side {
                grid[r * side + c] = col[r]
            }
        }
    }
    var out = [Int]()
    out.reserveCapacity(n)
    for r in 0..<side {
        if r % 2 == 0 {
            for c in 0..<side {
                if grid[r * side + c] != Int.max {
                    out.append(grid[r * side + c])
                }
            }
        } else {
            for c in stride(from: side - 1, through: 0, by: -1) {
                if grid[r * side + c] != Int.max {
                    out.append(grid[r * side + c])
                }
            }
        }
    }
    for i in 0..<n {
        a[i] = out[i]
    }
}
