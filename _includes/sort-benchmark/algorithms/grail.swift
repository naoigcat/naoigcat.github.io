/*
 * MIT License
 * Copyright (c) 2013 Andrey Astrelin
 * Copyright (c) 2020 The Holy Grail Sort Project
 * Swift port specialized to Int for the sort benchmark harness.
 */

private enum Subarray {
    case right
    case left
}

private let STATIC_SIZE = 4096

private func grail_sort_with_static_buffer(_ set: UnsafeMutableBufferPointer<Int>, _ len: Int) {
    var buffer = [Int](repeating: 0, count: STATIC_SIZE)
    buffer.withUnsafeMutableBufferPointer { buf in
        var container: UnsafeMutableBufferPointer<Int>? = buf
        grail_common_sort(set, 0, len, &container)
    }
}

private func grail_block_swap(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ point_a: Int,
    _ point_b: Int,
    _ block_len: Int
) {
    for i in 0..<block_len {
        set.swapAt(point_a + i, point_b + i)
    }
}

private func grail_rotate(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ left_len: Int,
    _ right_len: Int
) {
    var start = start
    var left_len = left_len
    var right_len = right_len
    while left_len > 0 && right_len > 0 {
        if left_len <= right_len {
            grail_block_swap(set, start, start + left_len, left_len)
            start += left_len
            right_len -= left_len
        } else {
            grail_block_swap(
                set,
                start + left_len - right_len,
                start + left_len,
                right_len
            )
            left_len -= right_len
        }
    }
}

private func grail_binary_search_left(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ length: Int,
    _ target: Int
) -> Int {
    var left = 0
    var right = length
    while left < right {
        let middle = left + ((right - left) / 2)
        if set[start + middle] < target {
            left = middle + 1
        } else {
            right = middle
        }
    }
    return left
}

private func grail_binary_search_right(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ length: Int,
    _ target: Int
) -> Int {
    var left = 0
    var right = length
    while left < right {
        let middle = left + ((right - left) / 2)
        if set[start + middle] > target {
            right = middle
        } else {
            left = middle + 1
        }
    }
    return right
}

private func grail_collect_keys(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ length: Int,
    _ ideal_keys: Int
) -> Int {
    var keys_found = 1
    var first_key = 0
    var current_key = 1
    while current_key < length && keys_found < ideal_keys {
        let insert_pos = grail_binary_search_left(
            set,
            start + first_key,
            keys_found,
            set[start + current_key]
        )
        if insert_pos == keys_found
            || set[start + current_key] != set[start + first_key + insert_pos]
        {
            grail_rotate(
                set,
                start + first_key,
                keys_found,
                current_key - (first_key + keys_found)
            )
            first_key = current_key - keys_found
            grail_rotate(
                set,
                start + first_key + insert_pos,
                keys_found - insert_pos,
                1
            )
            keys_found += 1
        }
        current_key += 1
    }
    grail_rotate(set, start, first_key, keys_found)
    return keys_found
}

private func grail_pairwise_swaps(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ length: Int
) {
    var index = 1
    while index < length {
        let left = start + index - 1
        let right = start + index
        if set[left] > set[right] {
            set.swapAt(left - 2, right)
            set.swapAt(right - 2, left)
        } else {
            set.swapAt(left - 2, left)
            set.swapAt(right - 2, right)
        }

        index += 2
    }

    let left = start + index - 1
    if left < start + length {
        set.swapAt(left - 2, left)
    }
}

private func grail_pairwise_writes(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ length: Int
) {
    var index = 1
    while index < length {
        let left = start + index - 1
        let right = start + index
        if set[left] > set[right] {
            set[left - 2] = set[right]
            set[right - 2] = set[left]
        } else {
            set[left - 2] = set[left]
            set[right - 2] = set[right]
        }

        index += 2
    }

    let left = start + index - 1
    if left < start + length {
        set[left - 2] = set[left]
    }
}

private func grail_block_select_sort(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ keys: Int,
    _ start: Int,
    _ median_key: Int,
    _ block_count: Int,
    _ block_len: Int
) -> Int {
    var median_key = median_key
    for block in 1..<block_count {
        let left = block - 1
        var right = left
        for index in block..<block_count {
            if set[start + (right * block_len)] > set[start + (index * block_len)] || set[start + (right * block_len)] == set[start + (index * block_len)] && set[keys + right] > set[keys + index]
            {
                right = index
            }
        }

        if right != left {
            grail_block_swap(
                set,
                start + (left * block_len),
                start + (right * block_len),
                block_len
            )
            set.swapAt(keys + left, keys + right)
            if median_key == left {
                median_key = right
            } else if median_key == right {
                median_key = left
            }
        }
    }
    return median_key
}

private func grail_merge_forwards(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ left_len: Int,
    _ right_len: Int,
    _ buffer_offset: Int
) {
    var left = start
    let middle = start + left_len
    var right = middle
    let end = middle + right_len
    var buffer = (start - buffer_offset)
    while right < end {
        if left == middle || set[left] > set[right] {
            set.swapAt(buffer, right)
            right += 1
        } else {
            set.swapAt(buffer, left)
            left += 1
        }
        buffer += 1
    }

    if buffer != left {
        grail_block_swap(set, buffer, left, middle - left)
    }
}

private func grail_merge_backwards(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ left_len: Int,
    _ right_len: Int,
    _ buffer_offset: Int
) {
    var left: Int = (start + left_len - 1)
    let middle = left
    var right = middle + right_len
    let end = start
    var buffer = (right + buffer_offset)
    while left >= end {
        if right == middle || set[left] > set[right] {
            set.swapAt(buffer, left)
            left -= 1
        } else {
            set.swapAt(buffer, right)
            right -= 1
        }
        buffer -= 1
    }
    if right != buffer {
        while right > middle {
            set.swapAt(buffer, right)
            buffer -= 1
            right -= 1
        }
    }
}

private func grail_out_of_place_merge(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ left_len: Int,
    _ right_len: Int,
    _ buffer_offset: Int
) {
    var left = start
    let middle = start + left_len
    var right = middle
    let end = middle + right_len
    var buffer = (start - buffer_offset)
    while right < end {
        if left == middle || set[left] > set[right] {
            set[buffer] = set[right]
            right += 1
        } else {
            set[buffer] = set[left]
            left += 1
        }
        buffer += 1
    }

    if buffer != left {
        while left < middle {
            set[buffer] = set[left]
            buffer += 1
            left += 1
        }
    }
}

private func grail_in_place_buffer_reset(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ reset_len: Int,
    _ buffer_len: Int
) {
    var index = start + reset_len - 1
    while index >= start {
        set.swapAt(index, index - buffer_len)
        index -= 1
    }
}

private func grail_out_of_place_buffer_reset(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ reset_len: Int,
    _ buffer_len: Int
) {
    var index = start + reset_len - 1
    while index >= start {
        set[index] = set[index - buffer_len]
        index -= 1
    }
}

private func grail_in_place_buffer_rewind(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ left_overs: Int,
    _ buffer: Int
) {
    var left_overs = left_overs
    var buffer = buffer
    while left_overs > start {
        buffer -= 1
        left_overs -= 1
        set.swapAt(buffer, left_overs)
    }
}

private func grail_out_of_place_buffer_rewind(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ left_overs: Int,
    _ buffer: Int
) {
    var left_overs = left_overs
    var buffer = buffer
    while left_overs > start {
        buffer -= 1
        left_overs -= 1
        set[buffer] = set[left_overs]
    }
}

private func grail_build_blocks(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ buffer: inout UnsafeMutableBufferPointer<Int>?,
    _ start: Int,
    _ length: Int,
    _ buffer_len: Int
) {
    if let buf = buffer {
        let extern_len: Int
        if buffer_len < buf.count {
            extern_len = buffer_len
        } else {
            var temp = 1
            while (temp * 2) <= buf.count {
                temp *= 2
            }
            extern_len = temp
        }

        grail_build_out_of_place(set, buf, start, length, buffer_len, extern_len)
    } else {
        grail_pairwise_swaps(set, start, length)
        grail_build_in_place(set, start - 2, length, 2, buffer_len)
    }
}

private func grail_build_out_of_place(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ buffer: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ length: Int,
    _ buffer_len: Int,
    _ extern_len: Int
) {
    var start = start
    do {
        let _len = (extern_len) - (0)
        for _i in 0..<_len {
            buffer[(0) + _i] = set[(start - extern_len) + _i]
        }
    }

    grail_pairwise_writes(set, start, length)
    start -= 2
    var merge_len = 2
    while merge_len < extern_len {
        var merge_index = start
        let both_merges = 2 * merge_len
        let merge_end = start + length - both_merges
        let buffer_offset: Int = merge_len
        while merge_index <= merge_end {
            grail_out_of_place_merge(set, merge_index, merge_len, merge_len, buffer_offset)
            merge_index += both_merges
        }
        let left_over = length - (merge_index - start)
        if left_over > merge_len {
            grail_out_of_place_merge(
                set,
                merge_index,
                merge_len,
                left_over - merge_len,
                buffer_offset
            )
        } else {
            for offset in 0..<left_over {
                set[merge_index + offset - merge_len] = set[merge_index + offset]
            }
        }

        start -= merge_len
        merge_len *= 2
    }

    do {
        let _len = (start + length + extern_len) - (start + length)
        for _i in 0..<_len {
            set[(start + length) + _i] = buffer[(0) + _i]
        }
    }
    grail_build_in_place(set, start, length, merge_len, buffer_len)
}

private func grail_build_in_place(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ length: Int,
    _ current_merge: Int,
    _ buffer_len: Int
) {
    var start = start
    var merge_len = current_merge
    while merge_len < buffer_len {
        var merge_index = start
        let both_merges = 2 * merge_len
        let merge_end = start + length - both_merges
        let buffer_offset: Int = merge_len
        while merge_index <= merge_end {
            grail_merge_forwards(set, merge_index, merge_len, merge_len, buffer_offset)
            merge_index += both_merges
        }

        let left_over = length - (merge_index - start)
        if left_over > merge_len {
            grail_merge_forwards(
                set,
                merge_index,
                merge_len,
                left_over - merge_len,
                buffer_offset
            )
        } else {
            grail_rotate(set, merge_index - merge_len, merge_len, left_over)
        }

        start -= merge_len
        merge_len *= 2
    }

    let both_merges = 2 * buffer_len
    let final_block = length % both_merges
    let final_offset = start + length - final_block
    if final_block <= buffer_len {
        grail_rotate(set, final_offset, final_block, buffer_len)
    } else {
        grail_merge_backwards(
            set,
            final_offset,
            buffer_len,
            final_block - buffer_len,
            buffer_len
        )
    }

    var merge_index: Int = final_offset - both_merges
    while merge_index >= start {
        grail_merge_backwards(
            set,
            merge_index,
            buffer_len,
            buffer_len,
            buffer_len
        )
        merge_index -= both_merges
    }
}

private func grail_count_left_blocks(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ offset: Int,
    _ block_count: Int,
    _ block_len: Int
) -> Int {
    var left_blocks = 0
    let first_right_block = offset + (block_count * block_len)
    var prev_left_block = first_right_block - block_len
    while left_blocks < block_count && set[first_right_block] < set[prev_left_block] {
        left_blocks += 1
        prev_left_block -= block_len
    }

    return left_blocks
}

private func grail_get_subarray(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ current_key: Int,
    _ median_key: Int
) -> Subarray {
    if set[current_key] < set[median_key] {
        return .left
    } else {
        return .right
    }
}

private func grail_smart_merge_out_of_place(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ left_len: inout Int,
    _ left_origin: inout Subarray,
    _ right_len: Int,
    _ buffer_offset: Int
) {
    var left = start
    let middle = start + left_len
    var right = middle
    let end = middle + right_len
    var buffer = start - buffer_offset
    if left_origin == .left {
        while left < middle && right < end {
            if set[left] <= set[right] {
                set[buffer] = set[left]
                left += 1
            } else {
                set[buffer] = set[right]
                right += 1
            }
            buffer += 1
        }
    } else {
        while left < middle && right < end {
            if set[left] < set[right] {
                set[buffer] = set[left]
                left += 1
            } else {
                set[buffer] = set[right]
                right += 1
            }
            buffer += 1
        }
    }

    if left < middle {
        left_len = middle - left
        grail_out_of_place_buffer_rewind(set, left, middle, end)
    } else {
        left_len = end - right
        if left_origin == .left {
            left_origin = .right
        } else {
            left_origin = .left
        }
    }
}

private func grail_smart_merge(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ left_len: inout Int,
    _ left_origin: inout Subarray,
    _ right_len: Int,
    _ buffer_offset: Int
) {
    var left = start
    let middle = start + left_len
    var right = middle
    let end = middle + right_len
    var buffer = start - buffer_offset
    if left_origin == .left {
        while left < middle && right < end {
            if set[left] <= set[right] {
                set.swapAt(buffer, left)
                left += 1
            } else {
                set.swapAt(buffer, right)
                right += 1
            }
            buffer += 1
        }
    } else {
        while left < middle && right < end {
            if set[left] < set[right] {
                set.swapAt(buffer, left)
                left += 1
            } else {
                set.swapAt(buffer, right)
                right += 1
            }
            buffer += 1
        }
    }

    if left < middle {
        left_len = middle - left
        grail_in_place_buffer_rewind(set, left, middle, end)
    } else {
        left_len = end - right
        if left_origin == .left {
            left_origin = .right
        } else {
            left_origin = .left
        }
    }
}

private func grail_smart_lazy_merge(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ left_len: inout Int,
    _ left_origin: inout Subarray,
    _ right_len: Int
) {
    var start = start
    var right_len = right_len
    if left_origin == .left {
        if set[start + left_len - 1] > set[start + left_len] {
            while left_len != 0 {
                let insert_pos =
                    grail_binary_search_left(set, start + left_len, right_len, set[start])
                if insert_pos != 0 {
                    grail_rotate(set, start, left_len, insert_pos)
                    start += insert_pos
                    right_len -= insert_pos
                }

                if right_len == 0 {
                    return
                } else {
                    start += 1
                    left_len -= 1
                    while left_len != 0 && set[start] <= set[start + left_len] {
                        start += 1
                        left_len -= 1
                    }
                }
            }
        }
    } else {
        if set[start + left_len - 1] >= set[start + left_len] {
            while left_len != 0 {
                let insert_pos =
                    grail_binary_search_right(set, start + left_len, right_len, set[start])
                if insert_pos != 0 {
                    grail_rotate(set, start, left_len, insert_pos)
                    start += insert_pos
                    right_len -= insert_pos
                }

                if right_len == 0 {
                    return
                } else {
                    start += 1
                    left_len -= 1
                    while left_len != 0 && set[start] < set[start + left_len] {
                        start += 1
                        left_len -= 1
                    }
                }
            }
        }
    }

    left_len = right_len
    if left_origin == .left {
        left_origin = .right
    } else {
        left_origin = .left
    }
}

private func grail_merge_blocks_out_of_place(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ keys: Int,
    _ median_key: Int,
    _ start: Int,
    _ block_count: Int,
    _ block_len: Int,
    _ final_left_blocks: Int,
    _ final_len: Int
) {
    var current_block = 0
    var block_index = block_len
    var current_block_len = block_len
    var current_block_origin = grail_get_subarray(set, keys, median_key)
    for key_index in 1..<block_count {
        current_block = block_index - current_block_len
        let next_block_origin = grail_get_subarray(set, keys + key_index, median_key)
        if next_block_origin == current_block_origin {
            internal_array_copy(
                set,
                start + current_block,
                start + current_block - block_len,
                current_block_len
            )
            current_block_len = block_len
        } else {
            grail_smart_merge_out_of_place(
                set,
                start + current_block,
                &current_block_len,
                &current_block_origin,
                block_len,
                block_len
            )
        }
        block_index += block_len
    }

    current_block = block_index - current_block_len
    if final_len != 0 {
        if current_block_origin == .right {
            internal_array_copy(
                set,
                start + current_block,
                start + current_block - block_len,
                current_block_len
            )
            current_block = block_index
            current_block_len = block_len * final_left_blocks
        } else {
            current_block_len += block_len * final_left_blocks
        }

        grail_out_of_place_merge(
            set,
            start + current_block,
            current_block_len,
            final_len,
            block_len
        )
    } else {
        internal_array_copy(
            set,
            start + current_block,
            start + current_block - block_len,
            current_block_len
        )
    }
}

private func internal_array_copy(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ src_position: Int,
    _ dest_position: Int,
    _ length: Int
) {
    for i in 0..<length {
        set[dest_position + i] = set[src_position + i]
    }
    //Generally optimized, using basic implementation here for clarity for now
}

private func grail_merge_blocks(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ keys: Int,
    _ median_key: Int,
    _ start: Int,
    _ block_count: Int,
    _ block_len: Int,
    _ final_left_blocks: Int,
    _ final_len: Int
) {
    var first_block = 0
    var block_index = block_len
    var first_block_len = block_len
    var first_block_origin: Subarray = set[keys] < set[median_key] ? .left : .right
    for key_index in 1..<block_count {
        first_block = block_index - first_block_len
        let next_block_origin: Subarray =
            set[keys + key_index] < set[median_key] ? .left : .right
        if next_block_origin == first_block_origin {
            grail_block_swap(
                set,
                start + first_block - block_len,
                start + first_block,
                first_block_len
            )
            first_block_len = block_len
        } else {
            grail_smart_merge(
                set,
                start + first_block,
                &first_block_len,
                &first_block_origin,
                block_len,
                block_len
            )
        }

        block_index += block_len
    }

    first_block = block_index - first_block_len
    if final_len != 0 {
        if first_block_origin == .right {
            grail_block_swap(
                set,
                start + first_block - block_len,
                start + first_block,
                first_block_len
            )
            first_block = block_index
            first_block_len = block_len * final_left_blocks
        } else {
            first_block_len += block_len * final_left_blocks
        }

        grail_merge_forwards(
            set,
            start + first_block,
            first_block_len,
            final_len,
            block_len
        )
    } else {
        grail_block_swap(
            set,
            start + first_block,
            start + first_block - block_len,
            first_block_len
        )
    }
}

private func grail_lazy_merge_blocks(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ keys: Int,
    _ median_key: Int,
    _ start: Int,
    _ block_count: Int,
    _ block_len: Int,
    _ final_left_blocks: Int,
    _ final_len: Int
) {
    var first_block = 0
    var block_index = block_len
    var first_block_len = block_len
    var first_block_origin: Subarray = set[keys] < set[median_key] ? .left : .right
    for key_index in 1..<block_count {
        first_block = block_index - first_block_len
        let next_block_origin: Subarray =
            set[keys + key_index] < set[median_key] ? .left : .right
        if next_block_origin == first_block_origin {
            first_block_len = block_len
        } else {
            grail_smart_lazy_merge(
                set,
                start + first_block,
                &first_block_len,
                &first_block_origin,
                block_len
            )
        }

        block_index += block_len
    }

    first_block = block_index - first_block_len
    if final_len != 0 {
        if first_block_origin == .right {
            first_block = block_index
            first_block_len = block_len * final_left_blocks
        } else {
            first_block_len += block_len * final_left_blocks
        }

        grail_lazy_merge(set, start + first_block, first_block_len, final_len)
    }
}

private func grail_combine_blocks(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ buffer: inout UnsafeMutableBufferPointer<Int>?,
    _ keys: Int,
    _ start: Int,
    _ length: Int,
    _ subarray_len: Int,
    _ block_len: Int,
    _ scrolling_buffer: Bool
) {
    var length = length
    let merge_count = length / (2 * subarray_len)
    var last_subarray = length - (2 * subarray_len * merge_count)
    if last_subarray <= subarray_len {
        length -= last_subarray
        last_subarray = 0
    }

    if let buf = buffer, scrolling_buffer && block_len <= buf.count {
        grail_combine_out_of_place(
            set,
            buf,
            keys,
            start,
            length,
            subarray_len,
            block_len,
            merge_count,
            last_subarray
        )
        return
    }

    grail_combine_in_place(
        set,
        keys,
        start,
        length,
        subarray_len,
        block_len,
        merge_count,
        last_subarray,
        scrolling_buffer
    )
}

private func grail_combine_out_of_place(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ buffer: UnsafeMutableBufferPointer<Int>,
    _ keys: Int,
    _ start: Int,
    _ length: Int,
    _ subarray_len: Int,
    _ block_len: Int,
    _ merge_count: Int,
    _ last_subarray: Int
) {
    do {
        let _len = (block_len) - (0)
        for _i in 0..<_len {
            buffer[(0) + _i] = set[(start - block_len) + _i]
        }
    }
    for merge_index in 0..<merge_count {
        let offset = start + (merge_index * (2 * subarray_len))
        let block_count = (2 * subarray_len) / block_len
        grail_insertion_sort(set, keys, block_count)
        var median_key = subarray_len / block_len
        median_key =
            grail_block_select_sort(set, keys, offset, median_key, block_count, block_len)
        grail_merge_blocks_out_of_place(
            set,
            keys,
            keys + median_key,
            offset,
            block_count,
            block_len,
            0,
            0
        )
    }

    if last_subarray != 0 {
        let offset = start + (merge_count * (2 * subarray_len))
        let right_blocks = last_subarray / block_len
        grail_insertion_sort(set, keys, right_blocks + 1)
        var median_key = subarray_len / block_len
        median_key =
            grail_block_select_sort(set, keys, offset, median_key, right_blocks, block_len)
        let last_fragment = last_subarray - (right_blocks * block_len)
        let left_blocks = if last_fragment != 0 {
            grail_count_left_blocks(set, offset, right_blocks, block_len)
        } else {
            0
        }
        let block_count = right_blocks - left_blocks
        if block_count == 0 {
            let left_length = left_blocks * block_len
            grail_out_of_place_merge(
                set,
                offset,
                left_length,
                last_fragment,
                block_len
            )
        } else {
            grail_merge_blocks_out_of_place(
                set,
                keys,
                keys + median_key,
                offset,
                block_count,
                block_len,
                left_blocks,
                last_fragment
            )
        }
    }
    grail_out_of_place_buffer_reset(set, start, length, block_len)
    do {
        let _len = (start) - (start - block_len)
        for _i in 0..<_len {
            set[(start - block_len) + _i] = buffer[(0) + _i]
        }
    }
}

private func grail_combine_in_place(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ keys: Int,
    _ start: Int,
    _ length: Int,
    _ subarray_len: Int,
    _ block_len: Int,
    _ merge_count: Int,
    _ last_subarray: Int,
    _ scrolling_buffer: Bool
) {
    for merge_index in 0..<merge_count {
        let offset = start + (merge_index * (2 * subarray_len))
        let block_count = (2 * subarray_len) / block_len
        grail_insertion_sort(set, keys, block_count)
        var median_key = subarray_len / block_len
        median_key =
            grail_block_select_sort(set, keys, offset, median_key, block_count, block_len)
        if scrolling_buffer {
            grail_merge_blocks(
                set,
                keys,
                keys + median_key,
                offset,
                block_count,
                block_len,
                0,
                0
            )
        } else {
            grail_lazy_merge_blocks(
                set,
                keys,
                keys + median_key,
                offset,
                block_count,
                block_len,
                0,
                0
            )
        }
    }

    if last_subarray != 0 {
        let offset = start + (merge_count * (2 * subarray_len))
        let right_blocks = last_subarray / block_len
        grail_insertion_sort(set, keys, right_blocks + 1)
        var median_key = subarray_len / block_len
        median_key =
            grail_block_select_sort(set, keys, offset, median_key, right_blocks, block_len)
        let last_fragment = last_subarray - (right_blocks * block_len)
        let left_blocks = if last_fragment != 0 {
            grail_count_left_blocks(set, offset, right_blocks, block_len)
        } else {
            0
        }
        let block_count = right_blocks - left_blocks
        if block_count == 0 {
            let left_length = left_blocks * block_len
            if scrolling_buffer {
                grail_merge_forwards(
                    set,
                    offset,
                    left_length,
                    last_fragment,
                    block_len
                )
            } else {
                grail_lazy_merge(set, offset, left_length, last_fragment)
            }
        } else {
            if scrolling_buffer {
                grail_merge_blocks(
                    set,
                    keys,
                    keys + median_key,
                    offset,
                    block_count,
                    block_len,
                    left_blocks,
                    last_fragment
                )
            } else {
                grail_lazy_merge_blocks(
                    set,
                    keys,
                    keys + median_key,
                    offset,
                    block_count,
                    block_len,
                    left_blocks,
                    last_fragment
                )
            }
        }
    }

    if scrolling_buffer {
        grail_in_place_buffer_reset(set, start, length, block_len)
    }
}

private func grail_lazy_merge(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ left_len: Int,
    _ right_len: Int
) {
    var start = start
    var left_len = left_len
    var right_len = right_len
    if left_len < right_len {
        while left_len != 0 {
            let insert_pos =
                grail_binary_search_left(set, start + left_len, right_len, set[start])
            if insert_pos != 0 {
                grail_rotate(set, start, left_len, insert_pos)
                start += insert_pos
                right_len -= insert_pos
            }

            if right_len == 0 {
                break
            } else {
                start += 1
                left_len -= 1
                while left_len != 0 && set[start] <= set[start + left_len] {
                    start += 1
                    left_len -= 1
                }
            }
        }
    } else {
        var end = start + left_len + right_len - 1
        while right_len != 0 {
            let insert_pos = grail_binary_search_right(set, start, left_len, set[end])
            if insert_pos != left_len {
                grail_rotate(set, start + insert_pos, left_len - insert_pos, right_len)
                end -= left_len - insert_pos
                left_len = insert_pos
            }

            if left_len == 0 {
                break
            } else {
                let left_end = start + left_len - 1
                end -= 1
                right_len -= 1
                while right_len != 0 && set[left_end] <= set[end] {
                    end -= 1
                    right_len -= 1
                }
            }
        }
    }
}

private func grail_lazy_stable_sort(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ length: Int
) {
    var index = 1
    while index < length {
        let left = start + index - 1
        let right = start + index
        if set[left] > set[right] {
            set.swapAt(left, right)
        }
        index += 2
    }
    var merge_len = 2
    while merge_len < length {
        var merge_index = 0
        // length need not be a power of two; the final pass can have
        // 2 * merge_len > length. Subtracting unchecked wraps Int and
        // drives grail_lazy_merge past the slice (few-key / all-equal paths).
        if length >= 2 * merge_len {
            let merge_end = length - (2 * merge_len)
            while merge_index <= merge_end {
                grail_lazy_merge(set, start + merge_index, merge_len, merge_len)
                merge_index += 2 * merge_len
            }
        }

        let left_over = length - merge_index
        if left_over > merge_len {
            grail_lazy_merge(
                set,
                start + merge_index,
                merge_len,
                left_over - merge_len
            )
        }

        merge_len *= 2
    }
}

private func grail_insertion_sort(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ length: Int
) {
    for item in 1..<length {
        var left: Int = (start + item - 1)
        var right: Int = (start + item)
        while left >= start && set[left] > set[right] {
            set.swapAt(left, right)
            left -= 1
            right -= 1
        }
    }
}

private func calc_min_keys(_ num_keys: Int, _ block_keys_sum: Int) -> Int {
    var block_keys_sum = block_keys_sum
    var min_keys = 1
    while min_keys < num_keys && block_keys_sum != 0 {
        min_keys *= 2
        block_keys_sum /= 8
    }
    return min_keys
}

private func grail_common_sort(
    _ set: UnsafeMutableBufferPointer<Int>,
    _ start: Int,
    _ length: Int,
    _ ext_buf: inout UnsafeMutableBufferPointer<Int>?
) {
    if length < 16 {
        //Grail Sort can only function on lengths >= 16 elements,
        //any smaller arrays are insertion sorted instead.
        grail_insertion_sort(set, start, length)
    } else {
        var block_len = 1
        while block_len * block_len < length {
            block_len *= 2
        }

        var key_len = ((length - 1) / block_len) + 1
        let ideal_keys = key_len + block_len
        let keys_found = grail_collect_keys(set, start, length, ideal_keys)
        let ideal_buffer: Bool
        if keys_found < ideal_keys {
            if keys_found < 4 {
                grail_lazy_stable_sort(set, start, length)
                return
            } else {
                key_len = block_len
                block_len = 0
                ideal_buffer = false
                while key_len > keys_found {
                    key_len /= 2
                }
            }
        } else {
            ideal_buffer = true
        }

        let buffer_end = block_len + key_len
        var subarray_len = ideal_buffer ? block_len : key_len
        if ideal_buffer {
            grail_build_blocks(
                set,
                &ext_buf,
                start + buffer_end,
                length - buffer_end,
                subarray_len
            )
        } else {
            var noBuf: UnsafeMutableBufferPointer<Int>? = nil
            grail_build_blocks(
                set,
                &noBuf,
                start + buffer_end,
                length - buffer_end,
                subarray_len
            )
        }

        while length - buffer_end > 2 * subarray_len {
            subarray_len *= 2
            var current_block_len = block_len
            var scrolling_buffer = ideal_buffer
            if !ideal_buffer {
                let half_key_len = key_len / 2
                if half_key_len * half_key_len >= 2 * subarray_len {
                    current_block_len = half_key_len
                    scrolling_buffer = true
                } else {
                    let block_keys_sum = (subarray_len * keys_found) / 2
                    let min_keys = calc_min_keys(key_len, block_keys_sum)
                    current_block_len = (2 * subarray_len) / min_keys
                }
            }
            grail_combine_blocks(
                set,
                &ext_buf,
                start,
                start + buffer_end,
                length - buffer_end,
                subarray_len,
                current_block_len,
                scrolling_buffer
            )
        }
        grail_insertion_sort(set, start, buffer_end)
        grail_lazy_merge(set, start, buffer_end, length - buffer_end)
    }
}

func grail_sort(_ a: inout [Int]) {
    a.withUnsafeMutableBufferPointer { grail_sort($0) }
}

func grail_sort(_ a: UnsafeMutableBufferPointer<Int>) {
    let len = a.count
    if len == 0 {
        return
    }
    grail_sort_with_static_buffer(a, len)
}
