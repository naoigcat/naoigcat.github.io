// Pedagogical Franceschini–Geffert skeleton:
// peel ~n/4 elements by rank, sort that prefix with the remaining suffix as a
// swap buffer via a high-arity heap (constant-ish height → few moves per element),
// then recurse on the unsorted suffix. The published algorithm adds sample /
// segment / bit-encoding machinery for full O(n)-move asymptotics; this port
// keeps the outer structure and the d-ary heap idea for measurement.

fn franceschini_branch_factor(len: usize) -> usize {
    if len <= 2 {
        return 2;
    }
    // Aim for heap height around 4: d ≈ n^(1/4).
    let mut d = 2usize;
    while d * d * d * d < len {
        d += 1;
        if d > 64 {
            break;
        }
    }
    d.max(2)
}

fn franceschini_child(parent: usize, which: usize, d: usize) -> usize {
    parent * d + 1 + which
}

fn franceschini_sift_down(a: &mut [usize], mut root: usize, end: usize, d: usize) {
    loop {
        let first = franceschini_child(root, 0, d);
        if first > end {
            break;
        }
        let mut best = first;
        let last = (first + d - 1).min(end);
        for child in first + 1..=last {
            if a[child] > a[best] {
                best = child;
            }
        }
        if a[root] >= a[best] {
            break;
        }
        a.swap(root, best);
        root = best;
    }
}

fn franceschini_dary_heap_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    let d = franceschini_branch_factor(n);
    let last_parent = (n - 2) / d;
    for start in (0..=last_parent).rev() {
        franceschini_sift_down(a, start, n - 1, d);
    }
    for end in (1..n).rev() {
        a.swap(0, end);
        if end > 1 {
            franceschini_sift_down(a, 0, end - 1, d);
        }
    }
}

fn franceschini_insertion_sort(a: &mut [usize]) {
    for i in 1..a.len() {
        let key = a[i];
        let mut j = i;
        while j > 0 && a[j - 1] > key {
            a[j] = a[j - 1];
            j -= 1;
        }
        a[j] = key;
    }
}

fn franceschini_partition_at(a: &mut [usize], left: usize, right: usize, pivot_index: usize) -> usize {
    a.swap(pivot_index, right);
    let pivot = a[right];
    let mut store = left;
    for i in left..right {
        if a[i] < pivot {
            a.swap(store, i);
            store += 1;
        }
    }
    a.swap(store, right);
    store
}

fn franceschini_quickselect(a: &mut [usize], mut left: usize, mut right: usize, k: usize) {
    while left < right {
        let mid = left + (right - left) / 2;
        // Median-of-three pivot index.
        if a[right] < a[left] {
            a.swap(left, right);
        }
        if a[mid] < a[left] {
            a.swap(left, mid);
        }
        if a[right] < a[mid] {
            a.swap(mid, right);
        }
        let pivot_index = franceschini_partition_at(a, left, right, mid);
        if k == pivot_index {
            return;
        } else if k < pivot_index {
            if pivot_index == 0 {
                return;
            }
            right = pivot_index - 1;
        } else {
            left = pivot_index + 1;
        }
    }
}

fn franceschini_sort_with_buffer(active: &mut [usize], buffer: &mut [usize]) {
    let m = active.len();
    if m == 0 {
        return;
    }
    debug_assert!(buffer.len() >= m);
    for i in 0..m {
        std::mem::swap(&mut active[i], &mut buffer[i]);
    }
    if m <= 32 {
        franceschini_insertion_sort(&mut buffer[..m]);
    } else {
        franceschini_dary_heap_sort(&mut buffer[..m]);
    }
    for i in 0..m {
        std::mem::swap(&mut active[i], &mut buffer[i]);
    }
}

fn franceschini_rec(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    if n <= 64 {
        if n <= 32 {
            franceschini_insertion_sort(a);
        } else {
            franceschini_dary_heap_sort(a);
        }
        return;
    }

    let rank = n / 4;
    franceschini_quickselect(a, 0, n - 1, rank);
    let pivot = a[rank];

    let mut split = 0usize;
    for i in 0..n {
        if a[i] < pivot {
            a.swap(split, i);
            split += 1;
        }
    }

    // Need a non-empty active prefix and a buffer at least as large.
    if split == 0 || split > n - split {
        franceschini_dary_heap_sort(a);
        return;
    }

    {
        let (left, right) = a.split_at_mut(split);
        franceschini_sort_with_buffer(left, right);
    }

    franceschini_rec(&mut a[split..]);
}

fn franceschini_sort(a: &mut [usize]) {
    franceschini_rec(a);
}
