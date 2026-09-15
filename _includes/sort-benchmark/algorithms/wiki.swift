let CACHE_SIZE: Int = 512

struct WikiRange {
    var start: Int
    var end: Int

    init(_ start: Int, _ end: Int) {
        self.start = start
        self.end = end
    }

    func len() -> Int {
        end - start
    }
}

final class WikiIterator {
    var size: Int
    var power_of_two: Int
    var numerator: Int
    var decimal: Int
    var denominator: Int
    var decimal_step: Int
    var numerator_step: Int

    init(_ size: Int, _ min_level: Int) {
        let power_of_two = floor_power_of_two(size)
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

    func next_range() -> WikiRange {
        let start = decimal
        decimal += decimal_step
        numerator += numerator_step
        if numerator >= denominator {
            numerator -= denominator
            decimal += 1
        }
        return WikiRange(start, decimal)
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

func floor_power_of_two(_ value: Int) -> Int {
    var x = value
    x |= x >> 1
    x |= x >> 2
    x |= x >> 4
    x |= x >> 8
    x |= x >> 16
    if Int.bitWidth >= 64 {
        x |= x >> 32
    }
    return x - (x >> 1)
}

func wiki_insertion_sort(_ a: UnsafeMutableBufferPointer<Int>, _ range: WikiRange) {
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

func wiki_reverse(_ a: UnsafeMutableBufferPointer<Int>, _ range: WikiRange) {
    let len = range.len()
    for index in (0..<(len / 2)).reversed() {
        a.swapAt(range.start + index, range.end - index - 1)
    }
}

func wiki_copy_within(_ a: UnsafeMutableBufferPointer<Int>, _ srcStart: Int, _ srcEnd: Int, _ dest: Int) {
    let count = srcEnd - srcStart
    if dest <= srcStart {
        for i in 0..<count {
            a[dest + i] = a[srcStart + i]
        }
    } else {
        for i in (0..<count).reversed() {
            a[dest + i] = a[srcStart + i]
        }
    }
}

func wiki_rotate(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ amount: Int,
    _ range: WikiRange,
    _ cache: UnsafeMutableBufferPointer<Int>,
    _ cache_size: Int
) {
    if range.len() == 0 {
        return
    }
    let split = range.start + amount
    let range1 = WikiRange(range.start, split)
    let range2 = WikiRange(split, range.end)
    if range1.len() <= range2.len() {
        if range1.len() <= cache_size {
            for i in 0..<range1.len() {
                cache[i] = a[range1.start + i]
            }
            wiki_copy_within(a, range2.start, range2.end, range1.start)
            let dest = range1.start + range2.len()
            for i in 0..<range1.len() {
                a[dest + i] = cache[i]
            }
            return
        }
    } else if range2.len() <= cache_size {
        for i in 0..<range2.len() {
            cache[i] = a[range2.start + i]
        }
        wiki_copy_within(a, range1.start, range1.end, range2.end - range1.len())
        for i in 0..<range2.len() {
            a[range1.start + i] = cache[i]
        }
        return
    }
    wiki_reverse(a, range1)
    wiki_reverse(a, range2)
    wiki_reverse(a, range)
}

func merge_into(
    _ from: UnsafeMutableBufferPointer<Int>,
    _ a: WikiRange,
    _ b: WikiRange,
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
                for i in 0..<(b.end - b_index) {
                    into[insert + i] = from[b_index + i]
                }
                break
            }
        } else {
            into[insert] = from[b_index]
            b_index += 1
            insert += 1
            if b_index == b.end {
                for i in 0..<(a.end - a_index) {
                    into[insert + i] = from[a_index + i]
                }
                break
            }
        }
    }
}

func merge_external(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ a_range: WikiRange,
    _ b: WikiRange,
    _ cache: UnsafeMutableBufferPointer<Int>
) {
    for i in 0..<a_range.len() {
        cache[i] = a[a_range.start + i]
    }
    var a_index = 0
    var b_index = b.start
    var insert = a_range.start
    let a_last = a_range.len()
    let b_last = b.end
    if b.len() > 0 && a_range.len() > 0 {
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

/// Backward merge when the right run fits in `cache`.
func merge_external_right(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ a_range: WikiRange,
    _ b: WikiRange,
    _ cache: UnsafeMutableBufferPointer<Int>
) {
    let right_len = b.len()
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

/// First index `i` in `a[start..<start+length]` with `a[i] >= target`.
func binary_search_left(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ length: Int,
    _ target: Int
) -> Int {
    var left = 0
    var right = length
    while left < right {
        let middle = left + ((right - left) / 2)
        if a[start + middle] < target {
            left = middle + 1
        } else {
            right = middle
        }
    }
    return left
}

/// Stable in-place merge via binary search + rotate, using the fixed cache when
/// either run fits (no O(n) heap buffer).
func merge_in_place(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ a_range: WikiRange,
    _ b: WikiRange,
    _ cache: UnsafeMutableBufferPointer<Int>,
    _ cache_size: Int
) {
    let left_len = a_range.len()
    let right_len = b.len()
    if left_len == 0 || right_len == 0 {
        return
    }
    if a[a_range.end - 1] <= a[b.start] {
        return
    }

    if left_len <= cache_size {
        merge_external(a, a_range, b, cache)
        return
    }
    if right_len <= cache_size {
        merge_external_right(a, a_range, b, cache)
        return
    }

    let rblock = left_len / 2
    let lblock = left_len - rblock
    let center = a[a_range.start + lblock]
    let left = binary_search_left(a, b.start, right_len, center)
    let right = right_len - left

    if left > 0 {
        // [ lblock | rblock | left | right ] → rotate middle band
        wiki_rotate(
            a,
            rblock,
            WikiRange(a_range.start + lblock, a_range.start + lblock + rblock + left),
            cache,
            cache_size
        )
        // Now: [ lblock | left | rblock | right ]
        merge_in_place(
            a,
            WikiRange(a_range.start, a_range.start + lblock),
            WikiRange(a_range.start + lblock, a_range.start + lblock + left),
            cache,
            cache_size
        )
        merge_in_place(
            a,
            WikiRange(a_range.start + lblock + left, a_range.start + lblock + left + rblock),
            WikiRange(
                a_range.start + lblock + left + rblock,
                a_range.start + lblock + left + rblock + right
            ),
            cache,
            cache_size
        )
    } else if right > 0 {
        merge_in_place(
            a,
            WikiRange(a_range.start + lblock, a_range.end),
            b,
            cache,
            cache_size
        )
    }
}

func merge_pair(
    _ a: UnsafeMutableBufferPointer<Int>,
    _ a_range: WikiRange,
    _ b: WikiRange,
    _ cache: UnsafeMutableBufferPointer<Int>,
    _ cache_size: Int
) {
    if a[b.end - 1] < a[a_range.start] {
        wiki_rotate(
            a,
            a_range.len(),
            WikiRange(a_range.start, b.end),
            cache,
            cache_size
        )
    } else if a[b.start] < a[a_range.end - 1] {
        if a_range.len() <= cache_size {
            merge_external(a, a_range, b, cache)
        } else {
            merge_in_place(a, a_range, b, cache, cache_size)
        }
    }
}

func wiki_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { wiki_sort($0) }
}

func wiki_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let size = a.count
    var cacheStorage = [Int](repeating: 0, count: CACHE_SIZE)
    let cache_size = CACHE_SIZE

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

        let iterator = WikiIterator(size, 4)
        iterator.begin()
        while !iterator.finished() {
            let range = iterator.next_range()
            wiki_insertion_sort(a, range)
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
                            for i in 0..<a1.len() {
                                cache[b1.len() + i] = a[a1.start + i]
                            }
                            for i in 0..<b1.len() {
                                cache[i] = a[b1.start + i]
                            }
                            merged1_len = a1.len() + b1.len()
                        } else if a[b1.start] < a[a1.end - 1] {
                            merge_into(a, a1, b1, cache)
                            merged1_len = a1.len() + b1.len()
                        } else if !(a[b2.start] < a[a2.end - 1]) && !(a[a2.start] < a[b1.end - 1]) {
                            continue
                        } else {
                            for i in 0..<a1.len() {
                                cache[i] = a[a1.start + i]
                            }
                            for i in 0..<b1.len() {
                                cache[a1.len() + i] = a[b1.start + i]
                            }
                            merged1_len = a1.len() + b1.len()
                        }
                        let a1Merged = WikiRange(a1.start, b1.end)
                        if a[b2.end - 1] < a[a2.start] {
                            for i in 0..<a2.len() {
                                cache[merged1_len + b2.len() + i] = a[a2.start + i]
                            }
                            for i in 0..<b2.len() {
                                cache[merged1_len + i] = a[b2.start + i]
                            }
                            merged2_len = a2.len() + b2.len()
                        } else if a[b2.start] < a[a2.end - 1] {
                            let cacheTail = UnsafeMutableBufferPointer(rebasing: cache[merged1_len...])
                            merge_into(a, a2, b2, cacheTail)
                            merged2_len = a2.len() + b2.len()
                        } else {
                            for i in 0..<a2.len() {
                                cache[merged1_len + i] = a[a2.start + i]
                            }
                            for i in 0..<b2.len() {
                                cache[merged1_len + a2.len() + i] = a[b2.start + i]
                            }
                            merged2_len = a2.len() + b2.len()
                        }
                        let a3 = WikiRange(0, merged1_len)
                        let b3 = WikiRange(merged1_len, merged1_len + merged2_len)
                        if cache[b3.end - 1] < cache[a3.start] {
                            for i in 0..<merged1_len {
                                a[a1Merged.start + merged2_len + i] = cache[a3.start + i]
                            }
                            for i in 0..<merged2_len {
                                a[a1Merged.start + i] = cache[b3.start + i]
                            }
                        } else if cache[b3.start] < cache[a3.end - 1] {
                            let into = UnsafeMutableBufferPointer(
                                rebasing: a[a1Merged.start..<(a1Merged.start + merged1_len + merged2_len)]
                            )
                            merge_into(cache, a3, b3, into)
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
                        merge_pair(a, a_range, b, cache, cache_size)
                    }
                }
            } else {
                iterator.begin()
                while !iterator.finished() {
                    let a_range = iterator.next_range()
                    let b = iterator.next_range()
                    merge_pair(a, a_range, b, cache, cache_size)
                }
            }
            if !iterator.next_level() {
                break
            }
        }
    }
}
