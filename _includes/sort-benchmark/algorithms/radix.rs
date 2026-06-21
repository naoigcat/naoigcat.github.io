fn counting_sort_by_digit(a: &mut [usize], exp: usize) {
    let n = a.len();
    let mut output = vec![0usize; n];
    let mut count = [0usize; 10];

    for &x in a.iter() {
        count[(x / exp) % 10] += 1;
    }

    for i in 1..10 {
        count[i] += count[i - 1];
    }

    for i in (0..n).rev() {
        let digit = (a[i] / exp) % 10;
        count[digit] -= 1;
        output[count[digit]] = a[i];
    }

    a.copy_from_slice(&output);
}

fn radix_sort(a: &mut [usize]) {
    if a.is_empty() {
        return;
    }

    let max = *a.iter().max().unwrap();
    let mut exp = 1usize;

    while max / exp > 0 {
        counting_sort_by_digit(a, exp);
        exp *= 10;
    }
}
