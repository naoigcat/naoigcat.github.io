fn pigeonhole_sort(a: &mut [usize]) {
    if a.is_empty() {
        return;
    }

    let min = *a.iter().min().unwrap();
    let max = *a.iter().max().unwrap();
    let span = max - min + 1;
    let mut holes: Vec<Vec<usize>> = vec![Vec::new(); span];

    for &x in a.iter() {
        holes[x - min].push(x);
    }

    let mut idx = 0;

    for hole in holes.iter() {
        for &x in hole.iter() {
            a[idx] = x;
            idx += 1;
        }
    }
}
