fn two_way_insertion_sort(a: &mut [usize]) {
    if a.is_empty() {
        return;
    }

    let mut last = 0usize;

    for i in 1..a.len() {
        if a[i] < a[0] {
            let key = a[i];
            for j in (0..=last).rev() {
                a[j + 1] = a[j];
            }
            a[0] = key;
            last += 1;
        } else if a[i] >= a[last] {
            last += 1;
            let key = a[i];
            for j in (last..i).rev() {
                a[j + 1] = a[j];
            }
            a[last] = key;
        } else {
            let mut k = last;
            while a[k] > a[i] {
                k -= 1;
            }
            let key = a[i];
            for j in (k + 1..i).rev() {
                a[j + 1] = a[j];
            }
            a[k + 1] = key;
            last += 1;
        }
    }
}
