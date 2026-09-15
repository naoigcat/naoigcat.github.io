fileprivate func kota_insertion_sort(_ a: UnsafeMutableBufferPointer<Int>, _ lo: Int, _ hi: Int) {
    for i in (lo + 1)..<hi {
        let key = a[i]
        var j = i
        while j > lo && a[j - 1] > key {
            a[j] = a[j - 1]
            j -= 1
        }
        a[j] = key
    }
}

fileprivate func kota_block_swap(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ block_len: Int,
    _ i: Int,
    _ j: Int
) {
    let bi = start + i * block_len
    let bj = start + j * block_len
    for k in 0..<block_len {
        a.swapAt(bi + k, bj + k)
    }
}

fileprivate func kota_block_select(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ block_count: Int,
    _ block_len: Int
) {
    for i in 0..<block_count {
        var min = i
        for j in (i + 1)..<block_count {
            if a[start + j * block_len] < a[start + min * block_len] {
                min = j
            }
        }
        if min != i {
            kota_block_swap(a, start, block_len, i, min)
        }
    }
}

fileprivate func kota_merge_with_buffer(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ lo: Int,
    _ mid: Int,
    _ hi: Int,
    _ buf: inout [Int]
) {
    let left_len = mid - lo
    if buf.count < left_len {
        buf.append(contentsOf: repeatElement(0, count: left_len - buf.count))
    } else if buf.count > left_len {
        buf.removeSubrange(left_len..<buf.count)
    }
    for i in 0..<left_len {
        buf[i] = a[lo + i]
    }
    var i = 0
    var j = mid
    var k = lo
    while i < left_len && j < hi {
        if buf[i] <= a[j] {
            a[k] = buf[i]
            i += 1
        } else {
            a[k] = a[j]
            j += 1
        }
        k += 1
    }
    while i < left_len {
        a[k] = buf[i]
        i += 1
        k += 1
    }
}

func kota_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { kota_sort($0) }
}

func kota_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let n = a.count
    if n <= 1 {
        return
    }

    let run_size = 16
    var block_len = Int(Double(n).squareRoot())
    block_len = max(block_len, 1)

    if n < run_size {
        kota_insertion_sort(a, 0, n)
        return
    }

    for start in stride(from: 0, to: n, by: run_size) {
        let end = min(start + run_size, n)
        kota_insertion_sort(a, start, end)
    }

    var merge_buf = [Int]()
    var width = run_size
    while width < n {
        for lo in stride(from: 0, to: n, by: width * 2) {
            let mid = min(lo + width, n)
            let hi = min(lo + width * 2, n)
            if mid >= hi {
                continue
            }
            kota_merge_with_buffer(a, lo, mid, hi, &merge_buf)
            let span = hi - lo
            if span >= block_len * 2 {
                let block_count = span / block_len
                kota_block_select(a, lo, block_count, block_len)
            }
        }
        width *= 2
    }
}
