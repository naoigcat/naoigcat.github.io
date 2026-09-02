struct PairingNode {
    key: usize,
    child: Option<Box<PairingNode>>,
    sibling: Option<Box<PairingNode>>,
}

fn meld(
    a: Option<Box<PairingNode>>,
    b: Option<Box<PairingNode>>,
) -> Option<Box<PairingNode>> {
    match (a, b) {
        (None, x) | (x, None) => x,
        (Some(mut x), Some(mut y)) => {
            if x.key <= y.key {
                y.sibling = x.child.take();
                x.child = Some(y);
                Some(x)
            } else {
                x.sibling = y.child.take();
                y.child = Some(x);
                Some(y)
            }
        }
    }
}

fn two_pass_meld(mut first: Option<Box<PairingNode>>) -> Option<Box<PairingNode>> {
    let mut pairs = Vec::new();
    while let Some(mut a) = first.take() {
        first = a.sibling.take();
        if let Some(mut b) = first.take() {
            first = b.sibling.take();
            pairs.push(meld(Some(a), Some(b)));
        } else {
            pairs.push(Some(a));
        }
    }

    let mut result = None;
    for pair in pairs.into_iter().rev() {
        result = meld(pair, result);
    }
    result
}

fn insert_key(heap: Option<Box<PairingNode>>, key: usize) -> Option<Box<PairingNode>> {
    let node = Box::new(PairingNode {
        key,
        child: None,
        sibling: None,
    });
    meld(heap, Some(node))
}

fn extract_min(heap: Option<Box<PairingNode>>) -> (Option<usize>, Option<Box<PairingNode>>) {
    let Some(mut root) = heap else {
        return (None, None);
    };
    let key = root.key;
    let children = root.child.take();
    (Some(key), two_pass_meld(children))
}

fn pairing_heap_sort(a: &mut [usize]) {
    let mut heap = None;
    for &key in a.iter() {
        heap = insert_key(heap, key);
    }
    for slot in a.iter_mut() {
        let (key, next) = extract_min(heap);
        heap = next;
        *slot = key.expect("pairing heap exhausted early");
    }
}
