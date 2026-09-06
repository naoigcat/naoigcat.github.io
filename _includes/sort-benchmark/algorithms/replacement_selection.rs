const HEAP_SIZE: usize = 32;

fn sift_down(heap: &mut [usize], mut i: usize) {
    let n = heap.len();
    loop {
        let left = 2 * i + 1;
        let right = left + 1;
        let mut smallest = i;
        if left < n && heap[left] < heap[smallest] {
            smallest = left;
        }
        if right < n && heap[right] < heap[smallest] {
            smallest = right;
        }
        if smallest == i {
            break;
        }
        heap.swap(i, smallest);
        i = smallest;
    }
}

fn sift_up(heap: &mut [usize], mut i: usize) {
    while i > 0 {
        let parent = (i - 1) / 2;
        if heap[i] >= heap[parent] {
            break;
        }
        heap.swap(i, parent);
        i = parent;
    }
}

fn heapify_min(heap: &mut [usize]) {
    if heap.len() <= 1 {
        return;
    }
    for i in (0..heap.len() / 2).rev() {
        sift_down(heap, i);
    }
}

fn heap_push(heap: &mut Vec<usize>, value: usize) {
    heap.push(value);
    let i = heap.len() - 1;
    sift_up(heap, i);
}

fn heap_pop_min(heap: &mut Vec<usize>) -> usize {
    let n = heap.len();
    debug_assert!(n > 0);
    let min = heap[0];
    let last = heap.pop().unwrap();
    if !heap.is_empty() {
        heap[0] = last;
        sift_down(heap, 0);
    }
    min
}

fn generate_runs(input: &[usize], mem: usize) -> Vec<Vec<usize>> {
    let n = input.len();
    let mut runs = Vec::new();
    if n == 0 {
        return runs;
    }

    let m = mem.min(n).max(1);
    let mut i = 0usize;
    let mut heap = Vec::with_capacity(m);
    while i < n && heap.len() < m {
        heap.push(input[i]);
        i += 1;
    }
    heapify_min(&mut heap);

    let mut frozen = Vec::with_capacity(m);
    let mut run = Vec::new();

    loop {
        if heap.is_empty() {
            if !run.is_empty() {
                runs.push(std::mem::take(&mut run));
            }
            if frozen.is_empty() && i >= n {
                break;
            }
            heap = std::mem::take(&mut frozen);
            while i < n && heap.len() < m {
                heap.push(input[i]);
                i += 1;
            }
            if heap.is_empty() {
                break;
            }
            heapify_min(&mut heap);
            continue;
        }

        let out = heap_pop_min(&mut heap);
        run.push(out);

        if i < n {
            let next = input[i];
            i += 1;
            if next >= out {
                heap_push(&mut heap, next);
            } else {
                frozen.push(next);
            }
        }
    }

    runs
}

fn merge_all_runs(runs: Vec<Vec<usize>>) -> Vec<usize> {
    if runs.is_empty() {
        return Vec::new();
    }
    let mut queue = runs;
    while queue.len() > 1 {
        let mut next = Vec::with_capacity((queue.len() + 1) / 2);
        let mut idx = 0;
        while idx + 1 < queue.len() {
            next.push(merge_values(&queue[idx], &queue[idx + 1]));
            idx += 2;
        }
        if idx < queue.len() {
            next.push(queue[idx].clone());
        }
        queue = next;
    }
    queue.pop().unwrap_or_default()
}

fn replacement_selection_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    let runs = generate_runs(a, HEAP_SIZE);
    let sorted = merge_all_runs(runs);
    a.copy_from_slice(&sorted);
}
