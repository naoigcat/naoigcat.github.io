const BURST_THRESHOLD: usize = 16;

#[derive(Default)]
struct BurstNode {
    children: [Option<Box<BurstNode>>; 10],
    bucket: Vec<usize>,
}

impl BurstNode {
    fn is_trie(&self) -> bool {
        self.children.iter().any(|c| c.is_some())
    }
}

fn max_digit_exp(max: usize) -> usize {
    let mut exp = 1usize;
    while exp.saturating_mul(10) <= max && exp <= usize::MAX / 10 {
        exp *= 10;
    }
    exp
}

fn burst_insert(node: &mut BurstNode, value: usize, exp: usize) {
    if node.is_trie() {
        if exp == 0 {
            node.bucket.push(value);
            return;
        }
        let digit = (value / exp) % 10;
        let child = node
            .children[digit]
            .get_or_insert_with(|| Box::new(BurstNode::default()));
        burst_insert(child, value, exp / 10);
        return;
    }

    node.bucket.push(value);
    if node.bucket.len() > BURST_THRESHOLD && exp > 0 {
        let exp_now = exp;
        let items = std::mem::take(&mut node.bucket);
        for v in items {
            let digit = (v / exp_now) % 10;
            let child = node
                .children[digit]
                .get_or_insert_with(|| Box::new(BurstNode::default()));
            burst_insert(child, v, exp_now / 10);
        }
    }
}

fn burst_collect(node: &BurstNode, out: &mut Vec<usize>) {
    if node.is_trie() {
        for child in node.children.iter().flatten() {
            burst_collect(child, out);
        }
    }
    if !node.bucket.is_empty() {
        let mut bucket = node.bucket.clone();
        insertion_sort(&mut bucket);
        out.extend(bucket);
    }
}

fn burst_sort(a: &mut [usize]) {
    if a.is_empty() {
        return;
    }

    let max = *a.iter().max().unwrap();
    let exp = max_digit_exp(max);
    let mut root = BurstNode::default();

    for &x in a.iter() {
        burst_insert(&mut root, x, exp);
    }

    let mut out = Vec::with_capacity(a.len());
    burst_collect(&root, &mut out);
    a.copy_from_slice(&out);
}
