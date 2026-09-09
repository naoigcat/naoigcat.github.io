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

// Skip cases larger than the algorithm's measured size cap (MAX_POWER). That
// cap exists because larger inputs are impractically slow; forcing them here
// would stall the published measurement script before any table rows print.
fn check_correctness_case_within_limit(label: &str, input: Vec<usize>) {
    if input.len() > (1usize << MAX_POWER) {
        return;
    }
    check_correctness_case(label, input);
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
    // Seed 0 is a fixed point of the xorshift below, so it would degenerate into
    // yet another all-equal case instead of a 4-value mix. Start at 1.
    for seed in 1..=32 {
        check_correctness_case(
            &format!("few_keys_len32_seed_{seed}"),
            few_unique_values(32, 4, seed),
        );
    }
    // Small-input cutoffs (insertion sort below 32 elements, etc.) hide duplicate-key
    // bugs in the recursive path, so repeat the duplicate cases at the smallest
    // benchmark size, which every algorithm must handle within reasonable time.
    check_correctness_case("all_equal_len256", vec![7; 256]);
    for seed in 1..=4 {
        check_correctness_case(
            &format!("few_keys_len256_seed_{seed}"),
            few_unique_values(256, 4, seed),
        );
    }
    // Blit's equal-key second sweep used to copy the whole range into a fixed
    // 512-element swap; lengths above that must still sort without panicking.
    // Respect MAX_POWER so algorithms with a low measured-size cap (slow,
    // sleep) do not hang here for minutes or months.
    check_correctness_case_within_limit("all_equal_len600", vec![7; 600]);
    for seed in 1..=4 {
        check_correctness_case_within_limit(
            &format!("few_keys_len2048_seed_{seed}"),
            few_unique_values(2048, 4, seed),
        );
    }
}
