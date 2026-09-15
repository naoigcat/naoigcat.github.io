func counting_sort_by_digit(_ a: UnsafeMutableBufferPointer<Int>, _ exp: Int) {
    let n = a.count
    var output = [Int](repeating: 0, count: n)
    var count = [Int](repeating: 0, count: 10)

    for i in 0..<n {
        count[(a[i] / exp) % 10] += 1
    }

    for i in 1..<10 {
        count[i] += count[i - 1]
    }

    for i in (0..<n).reversed() {
        let digit = (a[i] / exp) % 10
        count[digit] -= 1
        output[count[digit]] = a[i]
    }

    for i in 0..<n {
        a[i] = output[i]
    }
}

func radix_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { radix_sort($0) }
}

func radix_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.isEmpty {
        return
    }

    var max = a[0]
    for i in 1..<a.count {
        if a[i] > max {
            max = a[i]
        }
    }
    var exp = 1

    while max / exp > 0 {
        counting_sort_by_digit(a, exp)
        exp *= 10
    }
}
