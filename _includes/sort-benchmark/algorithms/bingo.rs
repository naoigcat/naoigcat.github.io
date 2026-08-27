fn bingo_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }

    let mut bingo = *a.iter().min().unwrap();
    let largest = *a.iter().max().unwrap();
    let mut next_bingo = largest;
    let mut next_pos = 0;

    while bingo < next_bingo {
        let start_pos = next_pos;
        for i in start_pos..n {
            if a[i] == bingo {
                a.swap(i, next_pos);
                next_pos += 1;
            } else if a[i] < next_bingo {
                next_bingo = a[i];
            }
        }
        bingo = next_bingo;
        next_bingo = largest;
    }
}
