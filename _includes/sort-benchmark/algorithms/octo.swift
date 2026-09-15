/// Educational stand-in for scandum's octosort (WikiSort + quadsort ideas).
/// Production uses block tagging for large in-place merges; here levels that
/// exceed the fixed cache use monobound search + Gries–Mills rotation so
/// auxiliary memory stays O(1). Reverse runs are handled by the octo swap.

fileprivate let OCTO_CACHE = 512

fileprivate struct OctoRange {
    var start: Int
    var end: Int

    init(_ start: Int, _ end: Int) {
        self.start = start
        self.end = end
    }

    var len: Int { end - start }
}

fileprivate final class OctoIterator {
    var size: Int
    var power_of_two: Int
    var numerator: Int
    var decimal: Int
    var denominator: Int
    var decimal_step: Int
    var numerator_step: Int

    init(_ size: Int, _ min_level: Int) {
        let power_of_two = octo_floor_power_of_two(size)
        let denominator = power_of_two / min_level
        self.size = size
        self.power_of_two = power_of_two
        self.numerator = 0
        self.decimal = 0
        self.denominator = denominator
        self.decimal_step = size / denominator
        self.numerator_step = size % denominator
    }

    func begin() {
        numerator = 0
        decimal = 0
    }

    func next_range() -> OctoRange {
        let start = decimal
        decimal += decimal_step
        numerator += numerator_step
        if numerator >= denominator {
            numerator -= denominator
            decimal += 1
        }
        return OctoRange(start, decimal)
    }

    func finished() -> Bool {
        decimal >= size
    }

    func next_level() -> Bool {
        decimal_step += decimal_step
        numerator_step += numerator_step
        if numerator_step >= denominator {
            numerator_step -= denominator
            decimal_step += 1
        }
        return decimal_step < size
    }

    func length() -> Int {
        decimal_step
    }
}

fileprivate func octo_floor_power_of_two(_ value: Int) -> Int {
    var x = value
    x |= x >> 1
    x |= x >> 2
    x |= x >> 4
    x |= x >> 8
    x |= x >> 16
    x |= x >> 32
    return x - (x >> 1)
}

fileprivate func octo_copy_within(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ src: Range<Int>,
    _ dest: Int
) {
    let n = src.count
    guard n > 0, let base = a.baseAddress else { return }
    memmove(
        base.advanced(by: dest),
        base.advanced(by: src.lowerBound),
        n * MemoryLayout<Int>.stride
    )
}

fileprivate func octo_insertion_sort(_ a: UnsafeMutableBufferPointer<Int>, _ range: OctoRange) {
    for i in (range.start + 1)..<range.end {
        let temp = a[i]
        var j = i
        while j > range.start && temp < a[j - 1] {
            a[j] = a[j - 1]
            j -= 1
        }
        a[j] = temp
    }
}

fileprivate func octo_tail_insert(_ a: UnsafeMutableBufferPointer<Int>, _ start: Int, _ i: Int) {
    let temp = a[i]
    var j = i
    while j > start && temp < a[j - 1] {
        a[j] = a[j - 1]
        j -= 1
    }
    a[j] = temp
}

/// Sorting network for four keys (stable for equals via `>`).
fileprivate func octo_swap4(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ i0: Int,
    _ i1: Int,
    _ i2: Int,
    _ i3: Int
) {
    if a[i0] > a[i1] {
        a.swapAt(i0, i1)
    }
    if a[i2] > a[i3] {
        a.swapAt(i2, i3)
    }
    if a[i0] > a[i2] {
        a.swapAt(i0, i2)
    }
    if a[i1] > a[i3] {
        a.swapAt(i1, i3)
    }
    if a[i1] > a[i2] {
        a.swapAt(i1, i2)
    }
}

fileprivate func octo_is_reverse4(_ a: UnsafeMutableBufferPointer<Int>, _ start: Int) -> Bool {
    a[start] > a[start + 1]
        && a[start + 2] > a[start + 3]
        && a[start + 1] > a[start + 2]
}

fileprivate func octo_range_nonincreasing(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ range: OctoRange
) -> Bool {
    for i in (range.start + 1)..<range.end {
        if a[i - 1] < a[i] {
            return false
        }
    }
    return true
}

/// Educational octo swap over a WikiIterator run (length 4..=8).
/// `rev_start` is the start of an unfinished reverse run; returns an updated
/// reverse-run start, or `nil` when no reverse run is pending.
fileprivate func octo_swap(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ range: OctoRange,
    _ rev_start: Int?
) -> Int? {
    let start = range.start
    let len = range.len
    if len == 0 {
        return rev_start
    }
    if len < 4 {
        if let rs = rev_start {
            var i = rs
            var j = start - 1
            while i < j {
                a.swapAt(i, j)
                i += 1
                j -= 1
            }
        }
        octo_insertion_sort(a, range)
        return nil
    }

    let can_extend_reverse = rev_start == nil
        || (start > 0 && a[start - 1] >= a[start])

    if octo_is_reverse4(a, start)
        && can_extend_reverse
        && octo_range_nonincreasing(a, range)
    {
        return rev_start ?? start
    }

    if let rs = rev_start {
        var i = rs
        var j = start - 1
        while i < j {
            a.swapAt(i, j)
            i += 1
            j -= 1
        }
    }

    if octo_is_reverse4(a, start) {
        a.swapAt(start, start + 3)
        a.swapAt(start + 1, start + 2)
    } else {
        octo_swap4(a, start, start + 1, start + 2, start + 3)
    }
    for i in (start + 4)..<range.end {
        octo_tail_insert(a, start, i)
    }
    return nil
}

fileprivate func octo_reverse_range(_ a: UnsafeMutableBufferPointer<Int>, _ range: OctoRange) {
    let len = range.len
    for index in 0..<(len / 2) {
        a.swapAt(range.start + index, range.end - index - 1)
    }
}

fileprivate func octo_swap_blocks(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ left: Int,
    _ right: Int,
    _ n: Int
) {
    for i in 0..<n {
        a.swapAt(left + i, right + i)
    }
}

/// Gries–Mills rotation via block swaps (cache-assisted when a side fits).
fileprivate func octo_rotate(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ amount: Int,
    _ range: OctoRange,
    _ cache: UnsafeMutableBufferPointer<Int>,
    _ cache_size: Int
) {
    if range.len == 0 || amount == 0 || amount == range.len {
        return
    }
    let split = range.start + amount
    let left_len = amount
    let right_len = range.len - amount

    if left_len <= right_len {
        if left_len <= cache_size {
            for i in 0..<left_len {
                cache[i] = a[range.start + i]
            }
            octo_copy_within(a, split..<range.end, range.start)
            for i in 0..<left_len {
                a[range.start + right_len + i] = cache[i]
            }
            return
        }
    } else if right_len <= cache_size {
        for i in 0..<right_len {
            cache[i] = a[split + i]
        }
        octo_copy_within(a, range.start..<split, range.start + right_len)
        for i in 0..<right_len {
            a[range.start + i] = cache[i]
        }
        return
    }

    // Gries–Mills: swap equal-sized blocks until the two sides balance.
    var i = left_len
    var j = right_len
    let mid = split
    while i != j {
        if i > j {
            octo_swap_blocks(a, mid - i, mid, j)
            i -= j
        } else {
            octo_swap_blocks(a, mid - i, mid + j - i, i)
            j -= i
        }
    }
    octo_swap_blocks(a, mid - i, mid, i)
}

fileprivate func octo_merge_into(
    _ from: UnsafeBufferPointer<Int>,
    _ a: OctoRange,
    _ b: OctoRange,
    _ into: UnsafeMutableBufferPointer<Int>
) {
    var a_index = a.start
    var b_index = b.start
    var insert = 0
    while true {
        if from[b_index] >= from[a_index] {
            into[insert] = from[a_index]
            a_index += 1
            insert += 1
            if a_index == a.end {
                for k in 0..<(b.end - b_index) {
                    into[insert + k] = from[b_index + k]
                }
                break
            }
        } else {
            into[insert] = from[b_index]
            b_index += 1
            insert += 1
            if b_index == b.end {
                for k in 0..<(a.end - a_index) {
                    into[insert + k] = from[a_index + k]
                }
                break
            }
        }
    }
}

fileprivate func octo_merge_into_mut(
    _ from: UnsafeMutableBufferPointer<Int>,
    _ a: OctoRange,
    _ b: OctoRange,
    _ into: UnsafeMutableBufferPointer<Int>
) {
    octo_merge_into(UnsafeBufferPointer(from), a, b, into)
}

fileprivate func octo_merge_external(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ a_range: OctoRange,
    _ b: OctoRange,
    _ cache: UnsafeMutableBufferPointer<Int>
) {
    for i in 0..<a_range.len {
        cache[i] = a[a_range.start + i]
    }
    var a_index = 0
    var b_index = b.start
    var insert = a_range.start
    let a_last = a_range.len
    let b_last = b.end
    if b.len > 0 && a_range.len > 0 {
        while true {
            if a[b_index] >= cache[a_index] {
                a[insert] = cache[a_index]
                a_index += 1
                insert += 1
                if a_index == a_last {
                    break
                }
            } else {
                a[insert] = a[b_index]
                b_index += 1
                insert += 1
                if b_index == b_last {
                    break
                }
            }
        }
    }
    for i in 0..<(a_last - a_index) {
        a[insert + i] = cache[a_index + i]
    }
}

/// Quadsort-style tail merge: right run fits in `cache`, merge backward.
fileprivate func octo_merge_external_right(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ a_range: OctoRange,
    _ b: OctoRange,
    _ cache: UnsafeMutableBufferPointer<Int>
) {
    let right_len = b.len
    for i in 0..<right_len {
        cache[i] = a[b.start + i]
    }
    var i = a_range.end
    var j = right_len
    var k = b.end
    while i > a_range.start && j > 0 {
        if a[i - 1] > cache[j - 1] {
            k -= 1
            i -= 1
            a[k] = a[i]
        } else {
            k -= 1
            j -= 1
            a[k] = cache[j]
        }
    }
    while j > 0 {
        k -= 1
        j -= 1
        a[k] = cache[j]
    }
}

/// Monobound binary search: first offset in `a[start..start+length)` with
/// `a[i] >= target` (scandum monobound style).
fileprivate func octo_monobound_search_left(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ length: Int,
    _ target: Int
) -> Int {
    if length == 0 {
        return 0
    }
    var end = start + length
    var top = length
    while top > 1 {
        let mid = top / 2
        if target <= a[end - mid] {
            end -= mid
        }
        top -= mid
    }
    if target <= a[end - 1] {
        return end - 1 - start
    } else {
        return end - start
    }
}

fileprivate func octo_merge_in_place(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ a_range: OctoRange,
    _ b: OctoRange,
    _ cache: UnsafeMutableBufferPointer<Int>,
    _ cache_size: Int
) {
    let left_len = a_range.len
    let right_len = b.len
    if left_len == 0 || right_len == 0 {
        return
    }
    if a[a_range.end - 1] <= a[b.start] {
        return
    }

    if left_len <= cache_size {
        octo_merge_external(a, a_range, b, cache)
        return
    }
    if right_len <= cache_size {
        octo_merge_external_right(a, a_range, b, cache)
        return
    }

    let rblock = left_len / 2
    let lblock = left_len - rblock
    let center = a[a_range.start + lblock]
    let left = octo_monobound_search_left(a, b.start, right_len, center)
    let right = right_len - left

    if left > 0 {
        octo_rotate(
            a,
            rblock,
            OctoRange(a_range.start + lblock, a_range.start + lblock + rblock + left),
            cache,
            cache_size
        )
        octo_merge_in_place(
            a,
            OctoRange(a_range.start, a_range.start + lblock),
            OctoRange(a_range.start + lblock, a_range.start + lblock + left),
            cache,
            cache_size
        )
        octo_merge_in_place(
            a,
            OctoRange(a_range.start + lblock + left, a_range.start + lblock + left + rblock),
            OctoRange(
                a_range.start + lblock + left + rblock,
                a_range.start + lblock + left + rblock + right
            ),
            cache,
            cache_size
        )
    } else if right > 0 {
        octo_merge_in_place(
            a,
            OctoRange(a_range.start + lblock, a_range.end),
            b,
            cache,
            cache_size
        )
    }
}

fileprivate func octo_merge_pair(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ a_range: OctoRange,
    _ b: OctoRange,
    _ cache: UnsafeMutableBufferPointer<Int>,
    _ cache_size: Int
) {
    if a[b.end - 1] < a[a_range.start] {
        octo_rotate(
            a,
            a_range.len,
            OctoRange(a_range.start, b.end),
            cache,
            cache_size
        )
    } else if a[b.start] < a[a_range.end - 1] {
        if a_range.len <= cache_size {
            octo_merge_external(a, a_range, b, cache)
        } else {
            octo_merge_in_place(a, a_range, b, cache, cache_size)
        }
    }
}

func octo_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { octo_sort($0) }
}

func octo_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let size = a.count
    var cacheStorage = [Int](repeating: 0, count: OCTO_CACHE)
    let cache_size = OCTO_CACHE

    cacheStorage.withUnsafeMutableBufferPointer { cache in
        if size < 4 {
            if size == 3 {
                if a[1] < a[0] {
                    a.swapAt(0, 1)
                }
                if a[2] < a[1] {
                    a.swapAt(1, 2)
                    if a[1] < a[0] {
                        a.swapAt(0, 1)
                    }
                }
            } else if size == 2 && a[1] < a[0] {
                a.swapAt(0, 1)
            }
            return
        }

        let iterator = OctoIterator(size, 4)
        iterator.begin()
        var rev_start: Int? = nil
        while !iterator.finished() {
            let range = iterator.next_range()
            rev_start = octo_swap(a, range, rev_start)
        }
        if let rs = rev_start {
            octo_reverse_range(a, OctoRange(rs, size))
            if rs == 0 {
                return
            }
        }
        if size < 8 {
            return
        }

        while true {
            if iterator.length() < cache_size {
                if (iterator.length() + 1) * 4 <= cache_size && iterator.length() * 4 <= size {
                    iterator.begin()
                    while !iterator.finished() {
                        let a1 = iterator.next_range()
                        let b1 = iterator.next_range()
                        let a2 = iterator.next_range()
                        let b2 = iterator.next_range()
                        var merged1_len = 0
                        var merged2_len = 0
                        if a[b1.end - 1] < a[a1.start] {
                            for i in 0..<a1.len {
                                cache[b1.len + i] = a[a1.start + i]
                            }
                            for i in 0..<b1.len {
                                cache[i] = a[b1.start + i]
                            }
                            merged1_len = a1.len + b1.len
                        } else if a[b1.start] < a[a1.end - 1] {
                            octo_merge_into_mut(a, a1, b1, cache)
                            merged1_len = a1.len + b1.len
                        } else if !(a[b2.start] < a[a2.end - 1]) && !(a[a2.start] < a[b1.end - 1]) {
                            continue
                        } else {
                            for i in 0..<a1.len {
                                cache[i] = a[a1.start + i]
                            }
                            for i in 0..<b1.len {
                                cache[a1.len + i] = a[b1.start + i]
                            }
                            merged1_len = a1.len + b1.len
                        }
                        let a1Merged = OctoRange(a1.start, b1.end)
                        if a[b2.end - 1] < a[a2.start] {
                            for i in 0..<a2.len {
                                cache[merged1_len + b2.len + i] = a[a2.start + i]
                            }
                            for i in 0..<b2.len {
                                cache[merged1_len + i] = a[b2.start + i]
                            }
                            merged2_len = a2.len + b2.len
                        } else if a[b2.start] < a[a2.end - 1] {
                            let into = UnsafeMutableBufferPointer(
                                rebasing: cache[merged1_len..<cache.count]
                            )
                            octo_merge_into_mut(a, a2, b2, into)
                            merged2_len = a2.len + b2.len
                        } else {
                            for i in 0..<a2.len {
                                cache[merged1_len + i] = a[a2.start + i]
                            }
                            for i in 0..<b2.len {
                                cache[merged1_len + a2.len + i] = a[b2.start + i]
                            }
                            merged2_len = a2.len + b2.len
                        }
                        let a3 = OctoRange(0, merged1_len)
                        let b3 = OctoRange(merged1_len, merged1_len + merged2_len)
                        if cache[b3.end - 1] < cache[a3.start] {
                            for i in 0..<merged1_len {
                                a[a1Merged.start + merged2_len + i] = cache[a3.start + i]
                            }
                            for i in 0..<merged2_len {
                                a[a1Merged.start + i] = cache[b3.start + i]
                            }
                        } else if cache[b3.start] < cache[a3.end - 1] {
                            let from = UnsafeBufferPointer(cache)
                            let into = UnsafeMutableBufferPointer(
                                rebasing: a[a1Merged.start..<(a1Merged.start + merged1_len + merged2_len)]
                            )
                            octo_merge_into(from, a3, b3, into)
                        } else {
                            for i in 0..<merged1_len {
                                a[a1Merged.start + i] = cache[a3.start + i]
                            }
                            for i in 0..<merged2_len {
                                a[a1Merged.start + merged1_len + i] = cache[b3.start + i]
                            }
                        }
                    }
                    _ = iterator.next_level()
                } else {
                    iterator.begin()
                    while !iterator.finished() {
                        let a_range = iterator.next_range()
                        let b = iterator.next_range()
                        octo_merge_pair(a, a_range, b, cache, cache_size)
                    }
                }
            } else {
                iterator.begin()
                while !iterator.finished() {
                    let a_range = iterator.next_range()
                    let b = iterator.next_range()
                    octo_merge_pair(a, a_range, b, cache, cache_size)
                }
            }
            if !iterator.next_level() {
                break
            }
        }
    }
}
