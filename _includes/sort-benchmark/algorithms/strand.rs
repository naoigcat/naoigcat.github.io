fn strand_sort(a: &mut [usize]) {
    let mut input = a.to_vec();
    let mut output = Vec::new();
    while !input.is_empty() {
        let mut strand = Vec::new();
        let mut rest = Vec::new();
        for value in input {
            if strand.last().map_or(true, |last| *last <= value) {
                strand.push(value);
            } else {
                rest.push(value);
            }
        }
        output = merge_values(&output, &strand);
        input = rest;
    }
    a.copy_from_slice(&output);
}
