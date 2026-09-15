let MEAN_BIN_SIZE: Int = 4
let MIN_BIN_COUNT: Int = 16

func rough_log2_size(_ n: Int) -> UInt32 {
    if n == 0 {
        return 0
    } else {
        return UInt32(Int.bitWidth - 1 - n.leadingZeroBitCount)
    }
}

func get_max_count(_ log_range: UInt32, _ count: Int) -> Int {
    let MAX_SPLITS: UInt32 = 11
    let LOG_CONST: UInt32 = 2
    let LOG_MEAN_BIN_SIZE: UInt32 = 2
    let LOG_MIN_SPLIT_COUNT: UInt32 = 4
    let data_size = UInt32(Int.bitWidth)

    let log_size = rough_log2_size(count)
    let denom = max(min(log_size, MAX_SPLITS), 1)
    var relative_width = (LOG_CONST * log_range) / denom
    if data_size <= relative_width {
        relative_width = data_size - 1
    }
    let shift: UInt32
    if relative_width < LOG_MEAN_BIN_SIZE + LOG_MIN_SPLIT_COUNT {
        shift = LOG_MEAN_BIN_SIZE + LOG_MIN_SPLIT_COUNT
    } else {
        shift = relative_width
    }
    return 1 << min(shift, 31)
}

func spread_bin_index(_ x: Int, _ min: Int, _ max: Int, _ bin_count: Int) -> Int {
    if max == min {
        return 0
    } else {
        let idx = Int((UInt64(x - min) * UInt64(bin_count)) / UInt64(max - min))
        return Swift.min(idx, Swift.max(bin_count - 1, 0))
    }
}

func spreadsort_rec(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    var max_val = 0
    for i in 0..<n {
        if a[i] > max_val {
            max_val = a[i]
        }
    }
    let max_count = get_max_count(rough_log2_size(max_val), n)
    if n < max_count {
        insertion_sort(a)
        return
    }

    var min = a[0]
    var max = a[0]
    for i in 1..<n {
        if a[i] < min { min = a[i] }
        if a[i] > max { max = a[i] }
    }
    if min == max {
        return
    }

    let log_range = rough_log2_size(max - min)
    let bin_count = Swift.min(Swift.max(n / MEAN_BIN_SIZE, MIN_BIN_COUNT), n)
    let range = max - min

    if bin_count >= range + 1 {
        insertion_sort(a)
        return
    }

    var count = [Int](repeating: 0, count: bin_count)
    for i in 0..<n {
        count[spread_bin_index(a[i], min, max, bin_count)] += 1
    }

    var offset = [Int](repeating: 0, count: bin_count + 1)
    for i in 0..<bin_count {
        offset[i + 1] = offset[i] + count[i]
    }

    var temp = [Int](repeating: 0, count: n)
    var cursor = offset
    for i in 0..<n {
        let bin = spread_bin_index(a[i], min, max, bin_count)
        temp[cursor[bin]] = a[i]
        cursor[bin] += 1
    }
    for i in 0..<n {
        a[i] = temp[i]
    }

    let fallback = get_max_count(log_range, n)
    for i in 0..<bin_count {
        let start = offset[i]
        let end = offset[i + 1]
        let len = end - start
        if len < 2 {
            continue
        }
        let slice = UnsafeMutableBufferPointer(rebasing: a[start..<end])
        if len < fallback {
            insertion_sort(slice)
        } else {
            spreadsort_rec(slice)
        }
    }
}

func spread_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { spread_sort($0) }
}

func spread_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    if a.count > 0 {
        spreadsort_rec(a)
    }
}
