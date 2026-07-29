#[derive(Clone, Copy)]
struct ShiversRun {
    lo: usize,
    hi: usize,
}

fn run_level(len: usize) -> u32 {
    debug_assert!(len > 0);
    (usize::BITS - 1 - len.leading_zeros()) as u32
}

fn merge_shivers_runs(a: &mut [usize], left: ShiversRun, right: ShiversRun) -> ShiversRun {
    let lo = left.lo;
    let hi = right.hi;
    let mid = left.hi + 1;
    let mut merged = Vec::with_capacity(hi - lo + 1);
    let (mut l, mut r) = (left.lo, mid);
    while l <= left.hi && r <= right.hi {
        if a[l] <= a[r] {
            merged.push(a[l]);
            l += 1;
        } else {
            merged.push(a[r]);
            r += 1;
        }
    }
    merged.extend_from_slice(&a[l..=left.hi]);
    merged.extend_from_slice(&a[r..=right.hi]);
    a[lo..=hi].copy_from_slice(&merged);
    ShiversRun { lo, hi }
}

fn prepare_shivers_run(a: &mut [usize], start: usize, min_run: usize) -> usize {
    let n = a.len();
    let mut i = start + 1;
    if i < n && a[i - 1] > a[i] {
        while i < n && a[i - 1] > a[i] {
            i += 1;
        }
        a[start..i].reverse();
    } else {
        while i < n && a[i - 1] <= a[i] {
            i += 1;
        }
    }
    let end = (start + min_run).min(n).max(i);
    insertion_sort(&mut a[start..end]);
    end
}

fn adaptive_shivers_sort(a: &mut [usize]) {
    const MIN_RUN: usize = 32;
    let n = a.len();
    if n <= 1 {
        return;
    }

    let mut pending: Vec<ShiversRun> = Vec::new();
    let mut start = 0usize;
    while start < n {
        let end = prepare_shivers_run(a, start, MIN_RUN);
        pending.push(ShiversRun {
            lo: start,
            hi: end - 1,
        });
        start = end;
    }

    let mut stack: Vec<ShiversRun> = Vec::new();
    let mut next = 0usize;
    loop {
        let h = stack.len();
        if h >= 3 {
            let r_hm2 = stack[h - 3];
            let r_hm1 = stack[h - 2];
            let r_h = stack[h - 1];
            let ell_hm2 = run_level(r_hm2.hi - r_hm2.lo + 1);
            let ell_hm1 = run_level(r_hm1.hi - r_hm1.lo + 1);
            let ell_h = run_level(r_h.hi - r_h.lo + 1);
            if ell_hm2 <= ell_hm1.max(ell_h) {
                let top = stack.pop().unwrap();
                let mid = stack.pop().unwrap();
                let left = stack.pop().unwrap();
                let merged = merge_shivers_runs(a, left, mid);
                stack.push(merged);
                stack.push(top);
                continue;
            }
        }
        if next < pending.len() {
            stack.push(pending[next]);
            next += 1;
            continue;
        }
        break;
    }

    while stack.len() >= 2 {
        let right = stack.pop().unwrap();
        let left = stack.pop().unwrap();
        stack.push(merge_shivers_runs(a, left, right));
    }
}
