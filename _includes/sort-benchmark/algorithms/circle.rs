fn circle_pass(a: &mut [usize], low: usize, high: usize) -> bool {
    if low >= high {
        return false;
    }

    let mut swapped = false;
    let mut left = low;
    let mut right = high;

    while left < right {
        if a[left] > a[right] {
            a.swap(left, right);
            swapped = true;
        }
        left += 1;
        right -= 1;
    }

    // Odd-length range: compare the middle element with its right neighbor.
    if left == right && right + 1 <= high && a[left] > a[right + 1] {
        a.swap(left, right + 1);
        swapped = true;
    }

    let mid = low + (high - low) / 2;
    let left_swapped = circle_pass(a, low, mid);
    let right_swapped = circle_pass(a, mid + 1, high);
    swapped || left_swapped || right_swapped
}

fn circle_sort(a: &mut [usize]) {
    let n = a.len();
    if n < 2 {
        return;
    }
    while circle_pass(a, 0, n - 1) {}
}
