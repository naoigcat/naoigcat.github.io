fn sift_down(a: &mut [usize], mut root: usize, end: usize) {
    loop {
        let child = root * 2 + 1;
        if child > end {
            break;
        }
        let mut swap_idx = child;
        if child < end && a[child] < a[child + 1] {
            swap_idx = child + 1;
        }
        if a[root] >= a[swap_idx] {
            break;
        }
        a.swap(root, swap_idx);
        root = swap_idx;
    }
}

fn heap_sort(a: &mut [usize]) {
    if a.len() <= 1 {
        return;
    }
    for start in (0..a.len() / 2).rev() {
        sift_down(a, start, a.len() - 1);
    }
    for end in (1..a.len()).rev() {
        a.swap(0, end);
        sift_down(a, 0, end - 1);
    }
}
