fn library_sort(a: &mut [usize]) {
    let mut shelf: Vec<usize> = Vec::with_capacity(a.len());
    for &value in a.iter() {
        let pos = shelf.binary_search(&value).unwrap_or_else(|pos| pos);
        shelf.insert(pos, value);
    }
    a.copy_from_slice(&shelf);
}
