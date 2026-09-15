func is_non_decreasing(_ a: [Int]) -> Bool {
    guard a.count >= 2 else { return true }
    for i in 1..<a.count {
        if a[i - 1] > a[i] { return false }
    }
    return true
}

func same_multiset(_ a: [Int], _ b: [Int]) -> Bool {
    if a.count != b.count {
        return false
    }

    var left = a
    var right = b
    left.sort()
    right.sort()
    return left == right
}

func check_correctness_case(_ label: String, _ input: [Int]) {
    var input = input
    let original = input

    benchmark_sort(&input)

    if !is_non_decreasing(input) {
        fatalError("correctness case \(label): output is not sorted")
    }

    if !same_multiset(input, original) {
        fatalError("correctness case \(label): elements were lost or added")
    }
}

// Skip cases larger than the algorithm's measured size cap (MAX_POWER). That
// cap exists because larger inputs are impractically slow; forcing them here
// would stall the published measurement script before any table rows print.
func check_correctness_case_within_limit(_ label: String, _ input: [Int]) {
    if input.count > (1 << MAX_POWER) {
        return
    }
    check_correctness_case(label, input)
}

func few_unique_values(_ size: Int, _ unique: Int, _ seed: UInt64) -> [Int] {
    var state = seed
    var result = [Int]()
    result.reserveCapacity(size)
    for _ in 0..<size {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        result.append(Int(state % UInt64(unique)) + 1)
    }
    return result
}

func run_correctness_checks() {
    check_correctness_case("empty", [])
    check_correctness_case("single", [42])
    check_correctness_case("duplicates", [3, 1, 3, 2, 1, 2])
    check_correctness_case("sorted", [1, 2, 3, 4, 5])
    check_correctness_case("reverse", [5, 4, 3, 2, 1])
    check_correctness_case("all_equal", [7, 7, 7, 7])
    check_correctness_case("skewed_range", [1_000_000, 2, 1_000_001, 1, 999_999])
    // Static-buffer Grail skips the in-buffer build when key collection is sparse
    // (ideal_buffer = false). Exercising that path catches regressions in buffer gating.
    check_correctness_case(
        "few_keys_len16",
        [2, 2, 2, 2, 2, 2, 2, 2, 4, 3, 1, 2, 3, 4, 1, 4]
    )
    // Seed 0 is a fixed point of the xorshift below, so it would degenerate into
    // yet another all-equal case instead of a 4-value mix. Start at 1.
    for seed in 1...32 {
        check_correctness_case(
            "few_keys_len32_seed_\(seed)",
            few_unique_values(32, 4, UInt64(seed))
        )
    }
    // Small-input cutoffs (insertion sort below 32 elements, etc.) hide duplicate-key
    // bugs in the recursive path, so repeat the duplicate cases at the smallest
    // benchmark size, which every algorithm must handle within reasonable time.
    check_correctness_case("all_equal_len256", [Int](repeating: 7, count: 256))
    for seed in 1...4 {
        check_correctness_case(
            "few_keys_len256_seed_\(seed)",
            few_unique_values(256, 4, UInt64(seed))
        )
    }
    // Blit's equal-key second sweep used to copy the whole range into a fixed
    // 512-element swap; lengths above that must still sort without panicking.
    // Respect MAX_POWER so algorithms with a low measured-size cap (slow,
    // sleep) do not hang here for minutes or months.
    check_correctness_case_within_limit("all_equal_len600", [Int](repeating: 7, count: 600))
    for seed in 1...4 {
        check_correctness_case_within_limit(
            "few_keys_len2048_seed_\(seed)",
            few_unique_values(2048, 4, UInt64(seed))
        )
    }
}
