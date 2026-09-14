/// Educational stand-in for scandum's octosort (WikiSort + quadsort ideas).
/// Production uses block tagging for large in-place merges; here levels that
/// exceed the fixed cache use monobound search + Gries–Mills rotation so
/// auxiliary memory stays O(1). Reverse runs are handled by the octo swap.

const OCTO_CACHE: usize = 512;

#[derive(Clone, Copy)]
struct Range {
    start: usize,
    end: usize,
}

impl Range {
    fn new(start: usize, end: usize) -> Self {
        Self { start, end }
    }

    fn len(self) -> usize {
        self.end - self.start
    }
}

struct OctoIterator {
    size: usize,
    power_of_two: usize,
    numerator: usize,
    decimal: usize,
    denominator: usize,
    decimal_step: usize,
    numerator_step: usize,
}

impl OctoIterator {
    fn new(size: usize, min_level: usize) -> Self {
        let power_of_two = floor_power_of_two(size);
        let denominator = power_of_two / min_level;
        Self {
            size,
            power_of_two,
            numerator: 0,
            decimal: 0,
            denominator,
            decimal_step: size / denominator,
            numerator_step: size % denominator,
        }
    }

    fn begin(&mut self) {
        self.numerator = 0;
        self.decimal = 0;
    }

    fn next_range(&mut self) -> Range {
        let start = self.decimal;
        self.decimal += self.decimal_step;
        self.numerator += self.numerator_step;
        if self.numerator >= self.denominator {
            self.numerator -= self.denominator;
            self.decimal += 1;
        }
        Range::new(start, self.decimal)
    }

    fn finished(&self) -> bool {
        self.decimal >= self.size
    }

    fn next_level(&mut self) -> bool {
        self.decimal_step += self.decimal_step;
        self.numerator_step += self.numerator_step;
        if self.numerator_step >= self.denominator {
            self.numerator_step -= self.denominator;
            self.decimal_step += 1;
        }
        self.decimal_step < self.size
    }

    fn length(&self) -> usize {
        self.decimal_step
    }
}

fn floor_power_of_two(value: usize) -> usize {
    let mut x = value;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    #[cfg(target_pointer_width = "64")]
    {
        x |= x >> 32;
    }
    x - (x >> 1)
}

fn octo_insertion_sort(a: &mut [usize], range: Range) {
    for i in range.start + 1..range.end {
        let temp = a[i];
        let mut j = i;
        while j > range.start && temp < a[j - 1] {
            a[j] = a[j - 1];
            j -= 1;
        }
        a[j] = temp;
    }
}

fn octo_tail_insert(a: &mut [usize], start: usize, i: usize) {
    let temp = a[i];
    let mut j = i;
    while j > start && temp < a[j - 1] {
        a[j] = a[j - 1];
        j -= 1;
    }
    a[j] = temp;
}

/// Sorting network for four keys (stable for equals via `>`).
fn octo_swap4(a: &mut [usize], i0: usize, i1: usize, i2: usize, i3: usize) {
    if a[i0] > a[i1] {
        a.swap(i0, i1);
    }
    if a[i2] > a[i3] {
        a.swap(i2, i3);
    }
    if a[i0] > a[i2] {
        a.swap(i0, i2);
    }
    if a[i1] > a[i3] {
        a.swap(i1, i3);
    }
    if a[i1] > a[i2] {
        a.swap(i1, i2);
    }
}

fn octo_is_reverse4(a: &[usize], start: usize) -> bool {
    a[start] > a[start + 1]
        && a[start + 2] > a[start + 3]
        && a[start + 1] > a[start + 2]
}

fn octo_range_nonincreasing(a: &[usize], range: Range) -> bool {
    for i in range.start + 1..range.end {
        if a[i - 1] < a[i] {
            return false;
        }
    }
    true
}

/// Educational octo swap over a WikiIterator run (length 4..=8).
/// `rev_start` is the start of an unfinished reverse run; returns an updated
/// reverse-run start, or `None` when no reverse run is pending.
fn octo_swap(a: &mut [usize], range: Range, rev_start: Option<usize>) -> Option<usize> {
    let start = range.start;
    let len = range.len();
    if len == 0 {
        return rev_start;
    }
    if len < 4 {
        if let Some(rs) = rev_start {
            a[rs..start].reverse();
        }
        octo_insertion_sort(a, range);
        return None;
    }

    let can_extend_reverse = rev_start.is_none()
        || (start > 0 && a[start - 1] >= a[start]);

    if octo_is_reverse4(a, start)
        && can_extend_reverse
        && octo_range_nonincreasing(a, range)
    {
        return Some(rev_start.unwrap_or(start));
    }

    if let Some(rs) = rev_start {
        a[rs..start].reverse();
    }

    if octo_is_reverse4(a, start) {
        a.swap(start, start + 3);
        a.swap(start + 1, start + 2);
    } else {
        octo_swap4(a, start, start + 1, start + 2, start + 3);
    }
    for i in start + 4..range.end {
        octo_tail_insert(a, start, i);
    }
    None
}

fn reverse_range(a: &mut [usize], range: Range) {
    let len = range.len();
    for index in 0..len / 2 {
        a.swap(range.start + index, range.end - index - 1);
    }
}

fn octo_swap_blocks(a: &mut [usize], left: usize, right: usize, n: usize) {
    for i in 0..n {
        a.swap(left + i, right + i);
    }
}

/// Gries–Mills rotation via block swaps (cache-assisted when a side fits).
fn rotate(
    a: &mut [usize],
    amount: usize,
    range: Range,
    cache: &mut [usize],
    cache_size: usize,
) {
    if range.len() == 0 || amount == 0 || amount == range.len() {
        return;
    }
    let split = range.start + amount;
    let left_len = amount;
    let right_len = range.len() - amount;

    if left_len <= right_len {
        if left_len <= cache_size {
            cache[..left_len].copy_from_slice(&a[range.start..split]);
            a.copy_within(split..range.end, range.start);
            a[range.start + right_len..range.end].copy_from_slice(&cache[..left_len]);
            return;
        }
    } else if right_len <= cache_size {
        cache[..right_len].copy_from_slice(&a[split..range.end]);
        a.copy_within(range.start..split, range.start + right_len);
        a[range.start..range.start + right_len].copy_from_slice(&cache[..right_len]);
        return;
    }

    // Gries–Mills: swap equal-sized blocks until the two sides balance.
    let mut i = left_len;
    let mut j = right_len;
    let mid = split;
    while i != j {
        if i > j {
            octo_swap_blocks(a, mid - i, mid, j);
            i -= j;
        } else {
            octo_swap_blocks(a, mid - i, mid + j - i, i);
            j -= i;
        }
    }
    octo_swap_blocks(a, mid - i, mid, i);
}

fn merge_into(from: &[usize], a: Range, b: Range, into: &mut [usize]) {
    let mut a_index = a.start;
    let mut b_index = b.start;
    let mut insert = 0;
    loop {
        if from[b_index] >= from[a_index] {
            into[insert] = from[a_index];
            a_index += 1;
            insert += 1;
            if a_index == a.end {
                into[insert..insert + b.end - b_index].copy_from_slice(&from[b_index..b.end]);
                break;
            }
        } else {
            into[insert] = from[b_index];
            b_index += 1;
            insert += 1;
            if b_index == b.end {
                into[insert..insert + a.end - a_index].copy_from_slice(&from[a_index..a.end]);
                break;
            }
        }
    }
}

fn merge_external(a: &mut [usize], a_range: Range, b: Range, cache: &mut [usize]) {
    cache[..a_range.len()].copy_from_slice(&a[a_range.start..a_range.end]);
    let mut a_index = 0;
    let mut b_index = b.start;
    let mut insert = a_range.start;
    let a_last = a_range.len();
    let b_last = b.end;
    if b.len() > 0 && a_range.len() > 0 {
        loop {
            if a[b_index] >= cache[a_index] {
                a[insert] = cache[a_index];
                a_index += 1;
                insert += 1;
                if a_index == a_last {
                    break;
                }
            } else {
                a[insert] = a[b_index];
                b_index += 1;
                insert += 1;
                if b_index == b_last {
                    break;
                }
            }
        }
    }
    a[insert..insert + a_last - a_index].copy_from_slice(&cache[a_index..a_last]);
}

/// Quadsort-style tail merge: right run fits in `cache`, merge backward.
fn merge_external_right(a: &mut [usize], a_range: Range, b: Range, cache: &mut [usize]) {
    let right_len = b.len();
    cache[..right_len].copy_from_slice(&a[b.start..b.end]);
    let mut i = a_range.end;
    let mut j = right_len;
    let mut k = b.end;
    while i > a_range.start && j > 0 {
        if a[i - 1] > cache[j - 1] {
            k -= 1;
            i -= 1;
            a[k] = a[i];
        } else {
            k -= 1;
            j -= 1;
            a[k] = cache[j];
        }
    }
    while j > 0 {
        k -= 1;
        j -= 1;
        a[k] = cache[j];
    }
}

/// Monobound binary search: first offset in `a[start..start+length)` with
/// `a[i] >= target` (scandum monobound style).
fn monobound_search_left(a: &[usize], start: usize, length: usize, target: usize) -> usize {
    if length == 0 {
        return 0;
    }
    let mut end = start + length;
    let mut top = length;
    while top > 1 {
        let mid = top / 2;
        if target <= a[end - mid] {
            end -= mid;
        }
        top -= mid;
    }
    if target <= a[end - 1] {
        end - 1 - start
    } else {
        end - start
    }
}

fn merge_in_place(
    a: &mut [usize],
    a_range: Range,
    b: Range,
    cache: &mut [usize],
    cache_size: usize,
) {
    let left_len = a_range.len();
    let right_len = b.len();
    if left_len == 0 || right_len == 0 {
        return;
    }
    if a[a_range.end - 1] <= a[b.start] {
        return;
    }

    if left_len <= cache_size {
        merge_external(a, a_range, b, cache);
        return;
    }
    if right_len <= cache_size {
        merge_external_right(a, a_range, b, cache);
        return;
    }

    let rblock = left_len / 2;
    let lblock = left_len - rblock;
    let center = a[a_range.start + lblock];
    let left = monobound_search_left(a, b.start, right_len, center);
    let right = right_len - left;

    if left > 0 {
        rotate(
            a,
            rblock,
            Range::new(a_range.start + lblock, a_range.start + lblock + rblock + left),
            cache,
            cache_size,
        );
        merge_in_place(
            a,
            Range::new(a_range.start, a_range.start + lblock),
            Range::new(a_range.start + lblock, a_range.start + lblock + left),
            cache,
            cache_size,
        );
        merge_in_place(
            a,
            Range::new(a_range.start + lblock + left, a_range.start + lblock + left + rblock),
            Range::new(
                a_range.start + lblock + left + rblock,
                a_range.start + lblock + left + rblock + right,
            ),
            cache,
            cache_size,
        );
    } else if right > 0 {
        merge_in_place(
            a,
            Range::new(a_range.start + lblock, a_range.end),
            b,
            cache,
            cache_size,
        );
    }
}

fn merge_pair(
    a: &mut [usize],
    a_range: Range,
    b: Range,
    cache: &mut [usize],
    cache_size: usize,
) {
    if a[b.end - 1] < a[a_range.start] {
        rotate(
            a,
            a_range.len(),
            Range::new(a_range.start, b.end),
            cache,
            cache_size,
        );
    } else if a[b.start] < a[a_range.end - 1] {
        if a_range.len() <= cache_size {
            merge_external(a, a_range, b, cache);
        } else {
            merge_in_place(a, a_range, b, cache, cache_size);
        }
    }
}

fn octo_sort(a: &mut [usize]) {
    let size = a.len();
    let mut cache = [0usize; OCTO_CACHE];
    let cache_size = OCTO_CACHE;

    if size < 4 {
        if size == 3 {
            if a[1] < a[0] {
                a.swap(0, 1);
            }
            if a[2] < a[1] {
                a.swap(1, 2);
                if a[1] < a[0] {
                    a.swap(0, 1);
                }
            }
        } else if size == 2 && a[1] < a[0] {
            a.swap(0, 1);
        }
        return;
    }

    let mut iterator = OctoIterator::new(size, 4);
    iterator.begin();
    let mut rev_start: Option<usize> = None;
    while !iterator.finished() {
        let range = iterator.next_range();
        rev_start = octo_swap(a, range, rev_start);
    }
    if let Some(rs) = rev_start {
        reverse_range(a, Range::new(rs, size));
        if rs == 0 {
            return;
        }
    }
    if size < 8 {
        return;
    }

    loop {
        if iterator.length() < cache_size {
            if (iterator.length() + 1) * 4 <= cache_size && iterator.length() * 4 <= size {
                iterator.begin();
                while !iterator.finished() {
                    let a1 = iterator.next_range();
                    let b1 = iterator.next_range();
                    let a2 = iterator.next_range();
                    let b2 = iterator.next_range();
                    let mut merged1_len = 0usize;
                    let mut merged2_len = 0usize;
                    if a[b1.end - 1] < a[a1.start] {
                        cache[b1.len()..b1.len() + a1.len()].copy_from_slice(&a[a1.start..a1.end]);
                        cache[..b1.len()].copy_from_slice(&a[b1.start..b1.end]);
                        merged1_len = a1.len() + b1.len();
                    } else if a[b1.start] < a[a1.end - 1] {
                        merge_into(a, a1, b1, &mut cache);
                        merged1_len = a1.len() + b1.len();
                    } else if !(a[b2.start] < a[a2.end - 1]) && !(a[a2.start] < a[b1.end - 1]) {
                        continue;
                    } else {
                        cache[..a1.len()].copy_from_slice(&a[a1.start..a1.end]);
                        cache[a1.len()..a1.len() + b1.len()].copy_from_slice(&a[b1.start..b1.end]);
                        merged1_len = a1.len() + b1.len();
                    }
                    let a1 = Range::new(a1.start, b1.end);
                    if a[b2.end - 1] < a[a2.start] {
                        cache[merged1_len + b2.len()..merged1_len + b2.len() + a2.len()]
                            .copy_from_slice(&a[a2.start..a2.end]);
                        cache[merged1_len..merged1_len + b2.len()]
                            .copy_from_slice(&a[b2.start..b2.end]);
                        merged2_len = a2.len() + b2.len();
                    } else if a[b2.start] < a[a2.end - 1] {
                        merge_into(a, a2, b2, &mut cache[merged1_len..]);
                        merged2_len = a2.len() + b2.len();
                    } else {
                        cache[merged1_len..merged1_len + a2.len()]
                            .copy_from_slice(&a[a2.start..a2.end]);
                        cache[merged1_len + a2.len()..merged1_len + a2.len() + b2.len()]
                            .copy_from_slice(&a[b2.start..b2.end]);
                        merged2_len = a2.len() + b2.len();
                    }
                    let a3 = Range::new(0, merged1_len);
                    let b3 = Range::new(merged1_len, merged1_len + merged2_len);
                    if cache[b3.end - 1] < cache[a3.start] {
                        a[a1.start + merged2_len..a1.start + merged2_len + merged1_len]
                            .copy_from_slice(&cache[a3.start..a3.end]);
                        a[a1.start..a1.start + merged2_len]
                            .copy_from_slice(&cache[b3.start..b3.end]);
                    } else if cache[b3.start] < cache[a3.end - 1] {
                        merge_into(
                            &cache,
                            a3,
                            b3,
                            &mut a[a1.start..a1.start + merged1_len + merged2_len],
                        );
                    } else {
                        a[a1.start..a1.start + merged1_len]
                            .copy_from_slice(&cache[a3.start..a3.end]);
                        a[a1.start + merged1_len..a1.start + merged1_len + merged2_len]
                            .copy_from_slice(&cache[b3.start..b3.end]);
                    }
                }
                iterator.next_level();
            } else {
                iterator.begin();
                while !iterator.finished() {
                    let a_range = iterator.next_range();
                    let b = iterator.next_range();
                    merge_pair(a, a_range, b, &mut cache, cache_size);
                }
            }
        } else {
            iterator.begin();
            while !iterator.finished() {
                let a_range = iterator.next_range();
                let b = iterator.next_range();
                merge_pair(a, a_range, b, &mut cache, cache_size);
            }
        }
        if !iterator.next_level() {
            break;
        }
    }
}
