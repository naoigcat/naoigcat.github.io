struct LeftistNode {
    key: usize,
    npl: i32,
    left: Option<Box<LeftistNode>>,
    right: Option<Box<LeftistNode>>,
}

fn npl(node: &Option<Box<LeftistNode>>) -> i32 {
    match node {
        None => -1,
        Some(n) => n.npl,
    }
}

fn merge(
    a: Option<Box<LeftistNode>>,
    b: Option<Box<LeftistNode>>,
) -> Option<Box<LeftistNode>> {
    match (a, b) {
        (None, x) | (x, None) => x,
        (Some(mut x), Some(mut y)) => {
            if x.key > y.key {
                std::mem::swap(&mut x, &mut y);
            }
            x.right = merge(x.right.take(), Some(y));
            if npl(&x.left) < npl(&x.right) {
                std::mem::swap(&mut x.left, &mut x.right);
            }
            x.npl = npl(&x.right) + 1;
            Some(x)
        }
    }
}

fn insert_key(heap: Option<Box<LeftistNode>>, key: usize) -> Option<Box<LeftistNode>> {
    let node = Box::new(LeftistNode {
        key,
        npl: 0,
        left: None,
        right: None,
    });
    merge(heap, Some(node))
}

fn extract_min(heap: Option<Box<LeftistNode>>) -> (Option<usize>, Option<Box<LeftistNode>>) {
    let Some(root) = heap else {
        return (None, None);
    };
    let key = root.key;
    let left = root.left;
    let right = root.right;
    (Some(key), merge(left, right))
}

fn leftist_heap_sort(a: &mut [usize]) {
    let mut heap = None;
    for &key in a.iter() {
        heap = insert_key(heap, key);
    }
    for slot in a.iter_mut() {
        let (key, next) = extract_min(heap);
        heap = next;
        *slot = key.expect("leftist heap exhausted early");
    }
}
