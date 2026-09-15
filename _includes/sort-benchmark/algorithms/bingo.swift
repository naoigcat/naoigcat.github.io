func bingo_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { bingo_sort($0) }
}

func bingo_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }

    var bingo = a.min()!
    let largest = a.max()!
    var next_bingo = largest
    var next_pos = 0

    while bingo < next_bingo {
        let start_pos = next_pos
        for i in start_pos..<n {
            if a[i] == bingo {
                a.swapAt(i, next_pos)
                next_pos += 1
            } else if a[i] < next_bingo {
                next_bingo = a[i]
            }
        }
        bingo = next_bingo
        next_bingo = largest
    }
}
