func two_way_insertion_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { two_way_insertion_sort($0) }
}

func two_way_insertion_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count == 0 {
        return
    }

    var last = 0

    for i in 1..<a.count {
        if a[i] < a[0] {
            let key = a[i]
            for j in (0...last).reversed() {
                a[j + 1] = a[j]
            }
            a[0] = key
            last += 1
        } else if a[i] >= a[last] {
            last += 1
            let key = a[i]
            for j in (last..<i).reversed() {
                a[j + 1] = a[j]
            }
            a[last] = key
        } else {
            var k = last
            while a[k] > a[i] {
                k -= 1
            }
            let key = a[i]
            for j in ((k + 1)..<i).reversed() {
                a[j + 1] = a[j]
            }
            a[k + 1] = key
            last += 1
        }
    }
}
