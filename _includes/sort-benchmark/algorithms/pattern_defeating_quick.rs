const INSERTION_SORT_THRESHOLD: usize = 24;
const NINTHER_THRESHOLD: usize = 128;
const PARTIAL_INSERTION_SORT_LIMIT: usize = 8;

fn floor_log2(n: usize) -> usize {
    usize::BITS as usize - n.leading_zeros() as usize - 1
}

fn sort2(a: &mut [usize], i: usize, j: usize) {
    if a[j] < a[i] {
        a.swap(i, j);
    }
}

fn sort3(a: &mut [usize], i: usize, j: usize, k: usize) {
    sort2(a, i, j);
    sort2(a, j, k);
    sort2(a, i, j);
}

fn partial_insertion_sort_range(a: &mut [usize], lo: usize, hi: usize) -> bool {
    if hi <= lo {
        return true;
    }
    let mut limit = 0usize;
    for i in (lo + 1)..=hi {
        if a[i] < a[i - 1] {
            let tmp = a[i];
            let mut j = i;
            loop {
                a[j] = a[j - 1];
                j -= 1;
                if j == lo || !(tmp < a[j - 1]) {
                    break;
                }
            }
            a[j] = tmp;
            limit += i - j;
            if limit > PARTIAL_INSERTION_SORT_LIMIT {
                return false;
            }
        }
    }
    true
}

/// Partition `[lo, hi]` around pivot at `lo`. Equals go to the right.
/// Returns `(pivot_pos, already_partitioned)`.
fn partition_right_range(a: &mut [usize], lo: usize, hi: usize) -> (usize, bool) {
    let pivot = a[lo];
    let mut first = lo;
    let mut last = hi + 1;

    loop {
        first += 1;
        if !(a[first] < pivot) {
            break;
        }
    }

    if first - 1 == lo {
        loop {
            if first >= last {
                break;
            }
            last -= 1;
            if a[last] < pivot {
                break;
            }
        }
    } else {
        loop {
            last -= 1;
            if a[last] < pivot {
                break;
            }
        }
    }

    let already_partitioned = first >= last;
    while first < last {
        a.swap(first, last);
        loop {
            first += 1;
            if !(a[first] < pivot) {
                break;
            }
        }
        loop {
            last -= 1;
            if a[last] < pivot {
                break;
            }
        }
    }

    let pivot_pos = first - 1;
    a[lo] = a[pivot_pos];
    a[pivot_pos] = pivot;
    (pivot_pos, already_partitioned)
}

/// Partition `[lo, hi]` around pivot at `lo`. Equals go to the left.
fn partition_left_range(a: &mut [usize], lo: usize, hi: usize) -> usize {
    let pivot = a[lo];
    let mut first = lo;
    let mut last = hi + 1;

    loop {
        last -= 1;
        if !(pivot < a[last]) {
            break;
        }
    }

    if last + 1 == hi + 1 {
        loop {
            if first >= last {
                break;
            }
            first += 1;
            if pivot < a[first] {
                break;
            }
        }
    } else {
        loop {
            first += 1;
            if pivot < a[first] {
                break;
            }
        }
    }

    while first < last {
        a.swap(first, last);
        loop {
            last -= 1;
            if !(pivot < a[last]) {
                break;
            }
        }
        loop {
            first += 1;
            if pivot < a[first] {
                break;
            }
        }
    }

    a[lo] = a[last];
    a[last] = pivot;
    last
}

fn pattern_defeating_quick_sort_loop(
    a: &mut [usize],
    mut lo: usize,
    hi: usize,
    mut bad_allowed: usize,
    mut leftmost: bool,
) {
    while lo <= hi {
        let size = hi - lo + 1;
        if size < INSERTION_SORT_THRESHOLD {
            insertion_sort(&mut a[lo..=hi]);
            return;
        }

        let s2 = size / 2;
        if size > NINTHER_THRESHOLD {
            sort3(a, lo, lo + s2, hi);
            sort3(a, lo + 1, lo + (s2 - 1), hi - 1);
            sort3(a, lo + 2, lo + (s2 + 1), hi - 2);
            sort3(a, lo + (s2 - 1), lo + s2, lo + (s2 + 1));
            a.swap(lo, lo + s2);
        } else {
            sort3(a, lo + s2, lo, hi);
        }

        if !leftmost && !(a[lo - 1] < a[lo]) {
            lo = partition_left_range(a, lo, hi) + 1;
            if lo > hi {
                return;
            }
            continue;
        }

        let (pivot_pos, already_partitioned) = partition_right_range(a, lo, hi);
        let l_size = pivot_pos - lo;
        let r_size = hi - pivot_pos;
        let highly_unbalanced = l_size < size / 8 || r_size < size / 8;

        if highly_unbalanced {
            if bad_allowed == 0 {
                heap_sort(&mut a[lo..=hi]);
                return;
            }
            bad_allowed -= 1;

            if l_size >= INSERTION_SORT_THRESHOLD {
                a.swap(lo, lo + l_size / 4);
                a.swap(pivot_pos - 1, pivot_pos - l_size / 4);
                if l_size > NINTHER_THRESHOLD {
                    a.swap(lo + 1, lo + (l_size / 4 + 1));
                    a.swap(lo + 2, lo + (l_size / 4 + 2));
                    a.swap(pivot_pos - 2, pivot_pos - (l_size / 4 + 1));
                    a.swap(pivot_pos - 3, pivot_pos - (l_size / 4 + 2));
                }
            }

            if r_size >= INSERTION_SORT_THRESHOLD {
                a.swap(pivot_pos + 1, pivot_pos + (1 + r_size / 4));
                a.swap(hi, hi + 1 - r_size / 4);
                if r_size > NINTHER_THRESHOLD {
                    a.swap(pivot_pos + 2, pivot_pos + (2 + r_size / 4));
                    a.swap(pivot_pos + 3, pivot_pos + (3 + r_size / 4));
                    a.swap(hi - 1, hi - (r_size / 4));
                    a.swap(hi - 2, hi - (1 + r_size / 4));
                }
            }
        } else if already_partitioned
            && (pivot_pos == lo || partial_insertion_sort_range(a, lo, pivot_pos - 1))
            && (pivot_pos >= hi || partial_insertion_sort_range(a, pivot_pos + 1, hi))
        {
            return;
        }

        if pivot_pos > lo {
            pattern_defeating_quick_sort_loop(a, lo, pivot_pos - 1, bad_allowed, leftmost);
        }
        lo = pivot_pos + 1;
        leftmost = false;
        if lo > hi {
            return;
        }
    }
}

fn pattern_defeating_quick_sort(a: &mut [usize]) {
    if a.len() <= 1 {
        return;
    }
    let bad_allowed = floor_log2(a.len());
    pattern_defeating_quick_sort_loop(a, 0, a.len() - 1, bad_allowed, true);
}
