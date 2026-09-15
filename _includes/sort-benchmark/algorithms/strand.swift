func strand_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { strand_sort($0) }
}

func strand_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    var input = Array(a)
    var output = [Int]()
    while !input.isEmpty {
        var strand = [Int]()
        var rest = [Int]()
        for value in input {
            if strand.last.map({ $0 <= value }) ?? true {
                strand.append(value)
            } else {
                rest.append(value)
            }
        }
        output = merge_values(output, strand)
        input = rest
    }
    for i in 0..<a.count {
        a[i] = output[i]
    }
}
