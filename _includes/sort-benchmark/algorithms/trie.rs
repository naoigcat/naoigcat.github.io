#[derive(Default)]
struct TrieNode {
    children: [Option<Box<TrieNode>>; 10],
    terminal: Vec<usize>,
}

fn max_digit_exp(max: usize) -> usize {
    let mut exp = 1usize;
    while exp.saturating_mul(10) <= max && exp <= usize::MAX / 10 {
        exp *= 10;
    }
    exp
}

fn trie_insert(node: &mut TrieNode, value: usize, exp: usize) {
    if exp == 0 {
        node.terminal.push(value);
        return;
    }
    let digit = (value / exp) % 10;
    let child = node.children[digit].get_or_insert_with(|| Box::new(TrieNode::default()));
    trie_insert(child, value, exp / 10);
}

fn trie_collect(node: &TrieNode, out: &mut Vec<usize>) {
    for child in node.children.iter().flatten() {
        trie_collect(child, out);
    }
    out.extend(node.terminal.iter().copied());
}

fn trie_sort(a: &mut [usize]) {
    if a.is_empty() {
        return;
    }

    let max = *a.iter().max().unwrap();
    let exp = max_digit_exp(max);
    let mut root = TrieNode::default();

    for &x in a.iter() {
        trie_insert(&mut root, x, exp);
    }

    let mut out = Vec::with_capacity(a.len());
    trie_collect(&root, &mut out);
    a.copy_from_slice(&out);
}
