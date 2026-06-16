#[derive(Clone, Copy)]
struct PowerRun {
    lo: usize,
    hi: usize,
    power: u32,
}

fn node_power(n: usize, b1: usize, e1: usize, b2: usize, e2: usize) -> u32 {
    let a = (b1 as f64 + (e1 - b1) as f64 / 2.0) / n as f64;
    let b = (b2 as f64 + (e2 - b2) as f64 / 2.0) / n as f64;
    let mut p = 0u32;
    while (a * 2f64.powi(p as i32)).floor() == (b * 2f64.powi(p as i32)).floor() {
        p += 1;
    }
    p
}

fn merge_power_runs(a: &mut [usize], left: PowerRun, right: PowerRun) -> PowerRun {
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
    PowerRun { lo, hi, power: 0 }
}

fn prepare_power_run(a: &mut [usize], start: usize, min_run: usize) -> usize {
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

fn power_sort(a: &mut [usize]) {
    const MIN_RUN: usize = 32;
    let n = a.len();
    if n <= 1 {
        return;
    }
    let mut stack: Vec<PowerRun> = Vec::new();
    let mut b1 = 0usize;
    let mut e1 = prepare_power_run(a, 0, MIN_RUN);
    while e1 < n {
        let b2 = e1;
        let e2 = prepare_power_run(a, b2, MIN_RUN);
        let p = node_power(n, b1, e1, b2, e2);
        while stack.last().is_some_and(|top| top.power > p) {
            let top = stack.pop().unwrap();
            let cur = PowerRun {
                lo: b1,
                hi: e1 - 1,
                power: 0,
            };
            let merged = merge_power_runs(a, top, cur);
            b1 = merged.lo;
            e1 = merged.hi + 1;
        }
        stack.push(PowerRun {
            lo: b1,
            hi: e1 - 1,
            power: p,
        });
        b1 = b2;
        e1 = e2;
    }
    while let Some(top) = stack.pop() {
        let cur = PowerRun {
            lo: b1,
            hi: e1 - 1,
            power: 0,
        };
        let merged = merge_power_runs(a, top, cur);
        b1 = merged.lo;
        e1 = merged.hi + 1;
    }
}
