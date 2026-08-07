// Pedagogical lazy funnelsort (Brodal–Fagerberg / Frigo-style skeleton):
// split into ~n^{1/3} contiguous blocks, recurse, then merge with a lazy
// k-merger — a binary tree of buffered binary mergers whose buffer sizes
// follow the recursive top/bottom split (cache-oblivious I/O is the point;
// this port keeps the control flow and buffer geometry for measurement).

fn funnel_cbrt_ceil(n: usize) -> usize {
    if n <= 1 {
        return n;
    }
    let mut x = (n as f64).cbrt().ceil() as usize;
    if x < 2 {
        x = 2;
    }
    while x * x * x < n {
        x += 1;
    }
    x
}

fn funnel_next_pow2(mut x: usize) -> usize {
    if x <= 2 {
        return 2;
    }
    x -= 1;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    #[cfg(target_pointer_width = "64")]
    {
        x |= x >> 32;
    }
    x + 1
}

fn funnel_buffer_cap(leaves: usize) -> usize {
    // α⌈k^{3/2}⌉-style capacity for a subtree with `leaves` inputs (α = 1).
    if leaves <= 1 {
        return 2;
    }
    let k = leaves as f64;
    ((k * k.sqrt()).ceil() as usize).max(2)
}

struct FunnelNode {
    /// Ring-style buffer: elements live in `buf[head..]` (internal nodes only).
    buf: Vec<usize>,
    head: usize,
    cap: usize,
    /// Leaf run `[lo, hi)` in the array being sorted; None for internal nodes.
    run: Option<(usize, usize)>,
    pos: usize,
    left: Option<usize>,
    right: Option<usize>,
    exhausted: bool,
}

impl FunnelNode {
    fn leaf(lo: usize, hi: usize) -> Self {
        Self {
            buf: Vec::new(),
            head: 0,
            cap: 0,
            run: Some((lo, hi)),
            pos: lo,
            left: None,
            right: None,
            exhausted: lo >= hi,
        }
    }

    fn internal(cap: usize, left: usize, right: usize) -> Self {
        Self {
            buf: Vec::with_capacity(cap),
            head: 0,
            cap,
            run: None,
            pos: 0,
            left: Some(left),
            right: Some(right),
            exhausted: false,
        }
    }

    fn buf_len(&self) -> usize {
        self.buf.len().saturating_sub(self.head)
    }

    fn buf_clear_consumed(&mut self) {
        if self.head > 0 {
            self.buf.drain(0..self.head);
            self.head = 0;
        }
    }

    fn buf_push(&mut self, v: usize) {
        self.buf_clear_consumed();
        self.buf.push(v);
    }

    fn buf_peek(&self) -> Option<usize> {
        self.buf.get(self.head).copied()
    }

    fn buf_pop(&mut self) -> Option<usize> {
        if self.head >= self.buf.len() {
            return None;
        }
        let v = self.buf[self.head];
        self.head += 1;
        if self.head == self.buf.len() {
            self.buf.clear();
            self.head = 0;
        }
        Some(v)
    }
}

fn funnel_build_tree(k: usize, runs: &[(usize, usize)]) -> (Vec<FunnelNode>, usize) {
    let mut nodes: Vec<FunnelNode> = Vec::with_capacity(2 * k);
    for i in 0..k {
        if i < runs.len() {
            nodes.push(FunnelNode::leaf(runs[i].0, runs[i].1));
        } else {
            nodes.push(FunnelNode::leaf(0, 0));
        }
    }
    let mut layer: Vec<usize> = (0..k).collect();
    let mut leaves_per: Vec<usize> = vec![1; k];
    while layer.len() > 1 {
        let mut next_layer = Vec::new();
        let mut next_leaves = Vec::new();
        let mut i = 0;
        while i < layer.len() {
            if i + 1 < layer.len() {
                let left = layer[i];
                let right = layer[i + 1];
                let leaves = leaves_per[i] + leaves_per[i + 1];
                let parent = nodes.len();
                nodes.push(FunnelNode::internal(funnel_buffer_cap(leaves), left, right));
                next_layer.push(parent);
                next_leaves.push(leaves);
                i += 2;
            } else {
                next_layer.push(layer[i]);
                next_leaves.push(leaves_per[i]);
                i += 1;
            }
        }
        layer = next_layer;
        leaves_per = next_leaves;
    }
    let root = layer[0];
    if nodes[root].run.is_none() {
        let total_leaves = runs.len().max(1);
        let want = (total_leaves as f64).powi(3).ceil() as usize;
        nodes[root].cap = nodes[root].cap.max(want).max(2);
        nodes[root].buf = Vec::with_capacity(nodes[root].cap);
    }
    (nodes, root)
}

fn funnel_leaf_has(nodes: &[FunnelNode], leaf: usize) -> bool {
    !nodes[leaf].exhausted
        && nodes[leaf]
            .run
            .map(|(lo, hi)| {
                let _ = lo;
                nodes[leaf].pos < hi
            })
            .unwrap_or(false)
}

fn funnel_leaf_peek(nodes: &[FunnelNode], leaf: usize, a: &[usize]) -> Option<usize> {
    if !funnel_leaf_has(nodes, leaf) {
        return None;
    }
    Some(a[nodes[leaf].pos])
}

fn funnel_leaf_pop(nodes: &mut [FunnelNode], leaf: usize, a: &[usize]) -> Option<usize> {
    let v = funnel_leaf_peek(nodes, leaf, a)?;
    nodes[leaf].pos += 1;
    if let Some((_, hi)) = nodes[leaf].run {
        if nodes[leaf].pos >= hi {
            nodes[leaf].exhausted = true;
        }
    }
    Some(v)
}

fn funnel_fill(nodes: &mut [FunnelNode], idx: usize, a: &[usize]) {
    if nodes[idx].run.is_some() || nodes[idx].exhausted {
        return;
    }
    let cap = nodes[idx].cap;
    while nodes[idx].buf_len() < cap {
        let left = nodes[idx].left.expect("internal");
        let right = nodes[idx].right.expect("internal");

        if nodes[left].run.is_none() && nodes[left].buf_len() == 0 && !nodes[left].exhausted {
            funnel_fill(nodes, left, a);
        }
        if nodes[right].run.is_none() && nodes[right].buf_len() == 0 && !nodes[right].exhausted {
            funnel_fill(nodes, right, a);
        }

        let left_ok = if nodes[left].run.is_some() {
            funnel_leaf_has(nodes, left)
        } else {
            nodes[left].buf_len() > 0
        };
        let right_ok = if nodes[right].run.is_some() {
            funnel_leaf_has(nodes, right)
        } else {
            nodes[right].buf_len() > 0
        };

        if !left_ok && !right_ok {
            nodes[idx].exhausted = true;
            break;
        }

        let take_left = if left_ok && right_ok {
            let lv = if nodes[left].run.is_some() {
                funnel_leaf_peek(nodes, left, a).unwrap()
            } else {
                nodes[left].buf_peek().unwrap()
            };
            let rv = if nodes[right].run.is_some() {
                funnel_leaf_peek(nodes, right, a).unwrap()
            } else {
                nodes[right].buf_peek().unwrap()
            };
            lv <= rv
        } else {
            left_ok
        };

        let v = if take_left {
            if nodes[left].run.is_some() {
                funnel_leaf_pop(nodes, left, a).unwrap()
            } else {
                nodes[left].buf_pop().unwrap()
            }
        } else if nodes[right].run.is_some() {
            funnel_leaf_pop(nodes, right, a).unwrap()
        } else {
            nodes[right].buf_pop().unwrap()
        };
        nodes[idx].buf_push(v);
    }
}

fn funnel_merge_runs(a: &mut [usize], runs: &[(usize, usize)], k: usize) {
    if runs.len() <= 1 {
        return;
    }
    let (mut nodes, root) = funnel_build_tree(k, runs);
    let total: usize = runs.iter().map(|(lo, hi)| hi - lo).sum();
    let mut out = Vec::with_capacity(total);
    while out.len() < total {
        funnel_fill(&mut nodes, root, a);
        if nodes[root].buf_len() == 0 {
            break;
        }
        let head = nodes[root].head;
        out.extend_from_slice(&nodes[root].buf[head..]);
        nodes[root].buf.clear();
        nodes[root].head = 0;
        if nodes[root].exhausted {
            break;
        }
    }
    debug_assert_eq!(out.len(), total);
    let base = runs[0].0;
    a[base..base + total].copy_from_slice(&out);
}

fn funnel_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 8 {
        insertion_sort(a);
        return;
    }
    let mut k = funnel_next_pow2(funnel_cbrt_ceil(n));
    while k > n {
        k /= 2;
    }
    k = k.max(2);

    let block = (n + k - 1) / k;
    let mut runs: Vec<(usize, usize)> = Vec::with_capacity(k);
    let mut i = 0;
    while i < n {
        let end = (i + block).min(n);
        funnel_sort(&mut a[i..end]);
        if end > i {
            runs.push((i, end));
        }
        i = end;
    }
    let merge_k = funnel_next_pow2(runs.len().max(2));
    funnel_merge_runs(a, &runs, merge_k);
}
