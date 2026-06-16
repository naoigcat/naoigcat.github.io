#[derive(Default)]
struct Node {
    value: usize,
    count: usize,
    left: Option<Box<Node>>,
    right: Option<Box<Node>>,
}

fn insert_node(root: &mut Option<Box<Node>>, value: usize) {
    match root {
        Some(node) if value < node.value => insert_node(&mut node.left, value),
        Some(node) if value > node.value => insert_node(&mut node.right, value),
        Some(node) => node.count += 1,
        None => {
            *root = Some(Box::new(Node {
                value,
                count: 1,
                left: None,
                right: None,
            }));
        }
    }
}

fn drain_node(root: &Option<Box<Node>>, out: &mut Vec<usize>) {
    if let Some(node) = root {
        drain_node(&node.left, out);
        out.extend(std::iter::repeat(node.value).take(node.count));
        drain_node(&node.right, out);
    }
}

fn tree_sort(a: &mut [usize]) {
    let mut root = None;
    for &value in a.iter() {
        insert_node(&mut root, value);
    }
    let mut out = Vec::with_capacity(a.len());
    drain_node(&root, &mut out);
    a.copy_from_slice(&out);
}
