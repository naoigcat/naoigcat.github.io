use std::sync::{Arc, Mutex};
use std::thread;

fn sleep_sort(a: &mut [usize]) {
    if a.is_empty() {
        return;
    }

    let n = a.len();
    let mut order: Vec<usize> = (0..n).collect();
    order.sort_by(|&i, &j| a[i].cmp(&a[j]).then(i.cmp(&j)));

    let mut rank = vec![0usize; n];
    for (r, &i) in order.iter().enumerate() {
        rank[i] = r;
    }

    let output = Arc::new(Mutex::new(vec![0usize; n]));
    let mut handles = Vec::with_capacity(n);

    for (idx, &value) in a.iter().enumerate() {
        let output = Arc::clone(&output);
        let slot = rank[idx];
        handles.push(thread::spawn(move || {
            let scaled = value.min(10_000) as u64;
            let micros = scaled * 100 + idx as u64 * 10;
            thread::sleep(Duration::from_micros(micros));
            output.lock().unwrap()[slot] = value;
        }));
    }

    for handle in handles {
        handle.join().unwrap();
    }

    let sorted = output.lock().unwrap().clone();
    a.copy_from_slice(&sorted);
}
