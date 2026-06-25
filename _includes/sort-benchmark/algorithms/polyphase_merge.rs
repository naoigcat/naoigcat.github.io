const NUM_TAPES: usize = 3;
const RUN_SIZE: usize = 32;

fn merge_runs(left: &[usize], right: &[usize]) -> Vec<usize> {
    let mut out = Vec::with_capacity(left.len() + right.len());
    let (mut i, mut j) = (0, 0);
    while i < left.len() && j < right.len() {
        if left[i] <= right[j] {
            out.push(left[i]);
            i += 1;
        } else {
            out.push(right[j]);
            j += 1;
        }
    }
    out.extend_from_slice(&left[i..]);
    out.extend_from_slice(&right[j..]);
    out
}

fn create_runs(a: &[usize], run_size: usize) -> Vec<Vec<usize>> {
    let mut runs = Vec::new();
    let mut i = 0;
    while i < a.len() {
        let end = (i + run_size).min(a.len());
        let mut run = a[i..end].to_vec();
        run.sort_unstable();
        runs.push(run);
        i = end;
    }
    runs
}

fn next_fibonacci_at_least(n: usize) -> (usize, usize) {
    let (mut prev, mut curr) = (1usize, 1usize);
    while curr < n {
        let next = prev + curr;
        prev = curr;
        curr = next;
    }
    (prev, curr)
}

fn distribute_fibonacci(runs: Vec<Vec<usize>>) -> [Vec<Vec<usize>>; NUM_TAPES] {
    let mut tapes: [Vec<Vec<usize>>; NUM_TAPES] = [vec![], vec![], vec![]];
    let n = runs.len();
    if n == 0 {
        return tapes;
    }
    if n == 1 {
        tapes[1].push(runs.into_iter().next().unwrap());
        return tapes;
    }

    let (fib_prev, fib_target) = next_fibonacci_at_least(n);
    let dummies = fib_target - n;
    let on_tape2 = fib_prev.saturating_sub(dummies);
    let on_tape1 = n - on_tape2;

    for (idx, run) in runs.into_iter().enumerate() {
        if idx < on_tape1 {
            tapes[1].push(run);
        } else {
            tapes[2].push(run);
        }
    }
    tapes
}

fn count_runs(tapes: &[Vec<Vec<usize>>; NUM_TAPES]) -> usize {
    tapes.iter().map(|t| t.len()).sum()
}

fn rotate_tapes(tapes: &mut [Vec<Vec<usize>>; NUM_TAPES]) {
    tapes.swap(0, 1);
    tapes.swap(1, 2);
}

fn polyphase_pass(tapes: &mut [Vec<Vec<usize>>; NUM_TAPES]) -> bool {
    let mut merged = false;
    while !tapes[1].is_empty() && !tapes[2].is_empty() {
        let left = tapes[1].remove(0);
        let right = tapes[2].remove(0);
        tapes[0].push(merge_runs(&left, &right));
        merged = true;
    }
    merged
}

fn merge_all_remaining(tapes: &mut [Vec<Vec<usize>>; NUM_TAPES]) -> Vec<usize> {
    let mut all: Vec<Vec<usize>> = Vec::new();
    for tape in tapes.iter() {
        all.extend(tape.iter().cloned());
    }
    while all.len() > 1 {
        let a = all.remove(0);
        let b = all.remove(0);
        all.push(merge_runs(&a, &b));
    }
    all.pop().unwrap_or_default()
}

fn polyphase_merge_sort(a: &mut [usize]) {
    if a.len() <= 1 {
        return;
    }
    let runs = create_runs(a, RUN_SIZE);
    if runs.len() <= 1 {
        if let Some(r) = runs.first() {
            a.copy_from_slice(r);
        }
        return;
    }

    let mut tapes = distribute_fibonacci(runs);
    let mut idle = 0usize;
    while count_runs(&tapes) > 1 {
        if polyphase_pass(&mut tapes) {
            rotate_tapes(&mut tapes);
            idle = 0;
        } else {
            idle += 1;
            if idle > NUM_TAPES * 4 {
                break;
            }
            rotate_tapes(&mut tapes);
        }
    }

    let result = if count_runs(&tapes) == 1 {
        tapes
            .iter()
            .find_map(|t| t.first().cloned())
            .unwrap_or_default()
    } else {
        merge_all_remaining(&mut tapes)
    };
    a.copy_from_slice(&result);
}
