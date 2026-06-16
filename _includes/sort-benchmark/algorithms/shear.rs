fn shear_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    let side = (n as f64).sqrt().ceil() as usize;
    let mut grid = vec![usize::MAX; side * side];
    grid[..n].copy_from_slice(a);
    let phases = ((side as f64).log2().ceil() as usize + 1) * 2;
    for _ in 0..phases {
        for r in 0..side {
            let row = &mut grid[r * side..(r + 1) * side];
            insertion_sort(row);
            if r % 2 == 1 {
                row.reverse();
            }
        }
        for c in 0..side {
            let mut col: Vec<usize> = (0..side).map(|r| grid[r * side + c]).collect();
            insertion_sort(&mut col);
            for r in 0..side {
                grid[r * side + c] = col[r];
            }
        }
    }
    let mut out = Vec::with_capacity(n);
    for r in 0..side {
        if r % 2 == 0 {
            for c in 0..side {
                if grid[r * side + c] != usize::MAX {
                    out.push(grid[r * side + c]);
                }
            }
        } else {
            for c in (0..side).rev() {
                if grid[r * side + c] != usize::MAX {
                    out.push(grid[r * side + c]);
                }
            }
        }
    }
    a.copy_from_slice(&out);
}
