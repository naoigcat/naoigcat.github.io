type Link = Option<Box<Node>>;

#[derive(Default)]
struct Node {
    value: usize,
    count: usize,
    left: Link,
    right: Link,
}

fn rotate_right(mut x: Box<Node>) -> Box<Node> {
    let mut y = x.left.take().expect("rotate_right");
    x.left = y.right.take();
    y.right = Some(x);
    y
}

fn rotate_left(mut x: Box<Node>) -> Box<Node> {
    let mut y = x.right.take().expect("rotate_left");
    x.right = y.left.take();
    y.left = Some(x);
    y
}

fn splay(mut root: Box<Node>, key: usize) -> Box<Node> {
    if key < root.value {
        if let Some(mut left) = root.left.take() {
            if key < left.value {
                if let Some(grand_left) = left.left.take() {
                    left.left = Some(splay(grand_left, key));
                    left = rotate_right(left);
                }
                root.left = Some(left);
                return rotate_right(root);
            }
            if key > left.value {
                left.right = left.right.take().map(|r| splay(r, key));
                if left.right.is_some() {
                    root.left = Some(rotate_left(left));
                    return rotate_right(root);
                }
                root.left = Some(left);
            } else {
                root.left = Some(left);
            }
        }
    } else if key > root.value {
        if let Some(mut right) = root.right.take() {
            if key > right.value {
                if let Some(grand_right) = right.right.take() {
                    right.right = Some(splay(grand_right, key));
                    right = rotate_left(right);
                }
                root.right = Some(right);
                return rotate_left(root);
            }
            if key < right.value {
                right.left = right.left.take().map(|l| splay(l, key));
                if right.left.is_some() {
                    root.right = Some(rotate_right(right));
                    return rotate_left(root);
                }
                root.right = Some(right);
            } else {
                root.right = Some(right);
            }
        }
    }
    root
}

fn splay_insert(root: Link, value: usize) -> Link {
    match root {
        None => Some(Box::new(Node {
            value,
            count: 1,
            left: None,
            right: None,
        })),
        Some(node) => {
            let mut node = splay(node, value);
            if node.value == value {
                node.count += 1;
                return Some(node);
            }
            if value < node.value {
                let mut new_node = Box::new(Node {
                    value,
                    count: 1,
                    left: node.left.take(),
                    right: None,
                });
                new_node.right = Some(node);
                Some(new_node)
            } else {
                let right = node.right.take();
                let mut new_node = Box::new(Node {
                    value,
                    count: 1,
                    left: None,
                    right,
                });
                new_node.left = Some(node);
                Some(new_node)
            }
        }
    }
}

fn drain_node(root: &Link, out: &mut Vec<usize>) {
    if let Some(node) = root {
        drain_node(&node.left, out);
        out.extend(std::iter::repeat(node.value).take(node.count));
        drain_node(&node.right, out);
    }
}

fn splay_sort(a: &mut [usize]) {
    let mut root = None;
    for &value in a.iter() {
        root = splay_insert(root, value);
    }
    let mut out = Vec::with_capacity(a.len());
    drain_node(&root, &mut out);
    a.copy_from_slice(&out);
}
