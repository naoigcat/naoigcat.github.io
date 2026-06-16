const CACHE_SIZE: usize = 512;

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

struct WikiIterator {
    size: usize,
    power_of_two: usize,
    numerator: usize,
    decimal: usize,
    denominator: usize,
    decimal_step: usize,
    numerator_step: usize,
}

impl WikiIterator {
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

fn wiki_insertion_sort(a: &mut [usize], range: Range) {
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

fn reverse(a: &mut [usize], range: Range) {
    let len = range.len();
    for index in (0..len / 2).rev() {
        a.swap(range.start + index, range.end - index - 1);
    }
}

fn rotate(a: &mut [usize], amount: usize, range: Range, cache: &mut [usize], cache_size: usize) {
    if range.len() == 0 {
        return;
    }
    let split = range.start + amount;
    let range1 = Range::new(range.start, split);
    let range2 = Range::new(split, range.end);
    if range1.len() <= range2.len() {
        if range1.len() <= cache_size {
            cache[..range1.len()].copy_from_slice(&a[range1.start..range1.end]);
            a.copy_within(range2.start..range2.end, range1.start);
            a[range1.start + range2.len()..range1.start + range2.len() + range1.len()]
                .copy_from_slice(&cache[..range1.len()]);
            return;
        }
    } else if range2.len() <= cache_size {
        cache[..range2.len()].copy_from_slice(&a[range2.start..range2.end]);
        a.copy_within(range1.start..range1.end, range2.end - range1.len());
        a[range1.start..range1.start + range2.len()].copy_from_slice(&cache[..range2.len()]);
        return;
    }
    reverse(a, range1);
    reverse(a, range2);
    reverse(a, range);
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
        if a_range.len() + b.len() <= cache_size {
            cache[..a_range.len()].copy_from_slice(&a[a_range.start..a_range.end]);
            merge_external(a, a_range, b, cache);
        } else {
            let mut merged = Vec::with_capacity(a_range.len() + b.len());
            let (mut i, mut j) = (a_range.start, b.start);
            while i < a_range.end && j < b.end {
                if a[i] <= a[j] {
                    merged.push(a[i]);
                    i += 1;
                } else {
                    merged.push(a[j]);
                    j += 1;
                }
            }
            merged.extend_from_slice(&a[i..a_range.end]);
            merged.extend_from_slice(&a[j..b.end]);
            a[a_range.start..b.end].copy_from_slice(&merged);
        }
    }
}

fn wiki_sort(a: &mut [usize]) {
    let size = a.len();
    let mut cache = [0usize; CACHE_SIZE];
    let cache_size = CACHE_SIZE;

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

    let mut iterator = WikiIterator::new(size, 4);
    iterator.begin();
    while !iterator.finished() {
        let range = iterator.next_range();
        wiki_insertion_sort(a, range);
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
                        cache[merged1_len..merged1_len + b2.len()].copy_from_slice(&a[b2.start..b2.end]);
                        merged2_len = a2.len() + b2.len();
                    } else if a[b2.start] < a[a2.end - 1] {
                        merge_into(a, a2, b2, &mut cache[merged1_len..]);
                        merged2_len = a2.len() + b2.len();
                    } else {
                        cache[merged1_len..merged1_len + a2.len()].copy_from_slice(&a[a2.start..a2.end]);
                        cache[merged1_len + a2.len()..merged1_len + a2.len() + b2.len()]
                            .copy_from_slice(&a[b2.start..b2.end]);
                        merged2_len = a2.len() + b2.len();
                    }
                    let a2 = Range::new(a2.start, b2.end);
                    let a3 = Range::new(0, merged1_len);
                    let b3 = Range::new(merged1_len, merged1_len + merged2_len);
                    if cache[b3.end - 1] < cache[a3.start] {
                        a[a1.start + merged2_len..a1.start + merged2_len + merged1_len]
                            .copy_from_slice(&cache[a3.start..a3.end]);
                        a[a1.start..a1.start + merged2_len].copy_from_slice(&cache[b3.start..b3.end]);
                    } else if cache[b3.start] < cache[a3.end - 1] {
                        merge_into(&cache, a3, b3, &mut a[a1.start..a1.start + merged1_len + merged2_len]);
                    } else {
                        a[a1.start..a1.start + merged1_len].copy_from_slice(&cache[a3.start..a3.end]);
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
