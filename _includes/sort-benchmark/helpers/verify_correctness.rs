fn is_non_decreasing(a: &[usize]) -> bool {
    a.windows(2).all(|w| w[0] <= w[1])
}

fn same_multiset(a: &[usize], b: &[usize]) -> bool {
    if a.len() != b.len() {
        return false;
    }

    let mut left = a.to_vec();
    let mut right = b.to_vec();
    left.sort_unstable();
    right.sort_unstable();
    left == right
}

fn check_correctness_case(label: &str, mut input: Vec<usize>) {
    let original = input.clone();

    benchmark_sort(&mut input);

    if !is_non_decreasing(&input) {
        panic!("correctness case {}: output is not sorted", label);
    }

    if !same_multiset(&input, &original) {
        panic!("correctness case {}: elements were lost or added", label);
    }
}

fn few_unique_values(size: usize, unique: usize, seed: u64) -> Vec<usize> {
    let mut state = seed;

    (0..size)
        .map(|_| {
            state ^= state << 13;
            state ^= state >> 7;
            state ^= state << 17;
            (state as usize % unique) + 1
        })
        .collect()
}

fn run_correctness_checks() {
    check_correctness_case("empty", vec![]);
    check_correctness_case("single", vec![42]);
    check_correctness_case("duplicates", vec![3, 1, 3, 2, 1, 2]);
    check_correctness_case("sorted", vec![1, 2, 3, 4, 5]);
    check_correctness_case("reverse", vec![5, 4, 3, 2, 1]);
    check_correctness_case("all_equal", vec![7, 7, 7, 7]);
    check_correctness_case("skewed_range", vec![1_000_000, 2, 1_000_001, 1, 999_999]);
    // Static-buffer Grail skips the in-buffer build when key collection is sparse
    // (ideal_buffer = false). Exercising that path catches regressions in buffer gating.
    check_correctness_case(
        "few_keys_len16",
        vec![2, 2, 2, 2, 2, 2, 2, 2, 4, 3, 1, 2, 3, 4, 1, 4],
    );
    for seed in 0..32 {
        check_correctness_case(
            &format!("few_keys_len32_seed_{seed}"),
            few_unique_values(32, 4, seed),
        );
    }
}
