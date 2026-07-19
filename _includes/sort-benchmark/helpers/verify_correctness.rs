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

fn run_correctness_checks() {
    check_correctness_case("empty", vec![]);
    check_correctness_case("single", vec![42]);
    check_correctness_case("duplicates", vec![3, 1, 3, 2, 1, 2]);
    check_correctness_case("sorted", vec![1, 2, 3, 4, 5]);
    check_correctness_case("reverse", vec![5, 4, 3, 2, 1]);
    check_correctness_case("all_equal", vec![7, 7, 7, 7]);
    check_correctness_case("skewed_range", vec![1_000_000, 2, 1_000_001, 1, 999_999]);
}
