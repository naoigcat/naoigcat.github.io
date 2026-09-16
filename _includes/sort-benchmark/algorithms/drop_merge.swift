func drop_merge_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { drop_merge_sort($0) }
}

func drop_merge_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n < 2 {
        return
    }

    let recency = 8
    let earlyOutTestAt = 4
    let earlyOutDisorderFraction = 0.60

    var dropped = [Int]()
    var numDroppedInRow = 0
    var write = 0
    var read = 0
    var iteration = 0
    let earlyOutStop = n / earlyOutTestAt

    while read < n {
        iteration += 1
        if iteration == earlyOutStop
            && Double(dropped.count) > Double(read) * earlyOutDisorderFraction
        {
            for i in 0..<dropped.count {
                a[write + i] = dropped[i]
            }
            quick_sort(a)
            return
        }

        if write == 0 || a[read] >= a[write - 1] {
            if read != write {
                a[write] = a[read]
            }
            read += 1
            write += 1
            numDroppedInRow = 0
        } else {
            if numDroppedInRow == 0
                && write >= 2
                && a[read] >= a[write - 2]
            {
                dropped.append(a[write - 1])
                a[write - 1] = a[read]
                read += 1
                continue
            }

            if numDroppedInRow < recency {
                dropped.append(a[read])
                read += 1
                numDroppedInRow += 1
            } else {
                dropped.removeLast(numDroppedInRow)
                read -= numDroppedInRow

                var numBacktracked = 1
                write -= 1

                var maxOfDropped = a[read]
                for i in 1...(numDroppedInRow) {
                    let v = a[read + i]
                    if v > maxOfDropped {
                        maxOfDropped = v
                    }
                }
                while write >= 1 && maxOfDropped < a[write - 1] {
                    numBacktracked += 1
                    write -= 1
                }

                for i in 0..<numBacktracked {
                    dropped.append(a[write + i])
                }
                numDroppedInRow = 0
            }
        }
    }

    quick_sort(&dropped)

    var back = n
    while let lastDropped = dropped.last {
        while write > 0 && lastDropped < a[write - 1] {
            a[back - 1] = a[write - 1]
            back -= 1
            write -= 1
        }
        a[back - 1] = lastDropped
        back -= 1
        dropped.removeLast()
    }
}
