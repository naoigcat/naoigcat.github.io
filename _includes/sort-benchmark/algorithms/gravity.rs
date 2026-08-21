fn gravity_sort(a: &mut [usize]) {
    if a.is_empty() {
        return;
    }

    let max = *a.iter().max().unwrap();
    if max == 0 {
        return;
    }

    let mut beads = vec![0usize; max];

    for &x in a.iter() {
        for bead in beads.iter_mut().take(x) {
            *bead += 1;
        }
    }

    let n = a.len();
    for i in (0..n).rev() {
        let mut sum = 0;
        for bead in beads.iter_mut() {
            if *bead == 0 {
                break;
            }
            sum += 1;
            *bead -= 1;
        }
        a[i] = sum;
    }
}
