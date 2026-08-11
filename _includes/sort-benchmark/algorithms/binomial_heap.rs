struct BinomialNode {
    key: usize,
    degree: u32,
    child: Option<Box<BinomialNode>>,
    sibling: Option<Box<BinomialNode>>,
}

fn link(mut child: Box<BinomialNode>, mut parent: Box<BinomialNode>) -> Box<BinomialNode> {
    child.sibling = parent.child.take();
    parent.child = Some(child);
    parent.degree += 1;
    parent
}

fn roots_to_vec(mut head: Option<Box<BinomialNode>>) -> Vec<Box<BinomialNode>> {
    let mut roots = Vec::new();
    while let Some(mut node) = head.take() {
        head = node.sibling.take();
        roots.push(node);
    }
    roots
}

fn vec_to_roots(roots: Vec<Box<BinomialNode>>) -> Option<Box<BinomialNode>> {
    let mut head: Option<Box<BinomialNode>> = None;
    let mut tail = &mut head;
    for node in roots {
        *tail = Some(node);
        tail = &mut tail.as_mut().unwrap().sibling;
    }
    head
}

fn merge_root_lists(
    mut a: Option<Box<BinomialNode>>,
    mut b: Option<Box<BinomialNode>>,
) -> Option<Box<BinomialNode>> {
    let mut merged = Vec::new();
    while a.is_some() && b.is_some() {
        if a.as_ref().unwrap().degree <= b.as_ref().unwrap().degree {
            let mut node = a.take().unwrap();
            a = node.sibling.take();
            merged.push(node);
        } else {
            let mut node = b.take().unwrap();
            b = node.sibling.take();
            merged.push(node);
        }
    }
    while let Some(mut node) = a.take() {
        a = node.sibling.take();
        merged.push(node);
    }
    while let Some(mut node) = b.take() {
        b = node.sibling.take();
        merged.push(node);
    }
    vec_to_roots(merged)
}

fn consolidate(head: Option<Box<BinomialNode>>) -> Option<Box<BinomialNode>> {
    let mut roots = roots_to_vec(head);
    let mut i = 0;
    while i + 1 < roots.len() {
        if roots[i].degree != roots[i + 1].degree {
            i += 1;
            continue;
        }
        // Three equal degrees: leave the first and merge the latter two (CLRS).
        if i + 2 < roots.len() && roots[i + 2].degree == roots[i].degree {
            i += 1;
            continue;
        }
        let a = roots.remove(i);
        let b = roots.remove(i);
        let linked = if a.key <= b.key {
            link(b, a)
        } else {
            link(a, b)
        };
        roots.insert(i, linked);
    }
    vec_to_roots(roots)
}

fn union(
    h1: Option<Box<BinomialNode>>,
    h2: Option<Box<BinomialNode>>,
) -> Option<Box<BinomialNode>> {
    consolidate(merge_root_lists(h1, h2))
}

fn insert_key(heap: Option<Box<BinomialNode>>, key: usize) -> Option<Box<BinomialNode>> {
    let node = Box::new(BinomialNode {
        key,
        degree: 0,
        child: None,
        sibling: None,
    });
    union(heap, Some(node))
}

fn reverse_children(mut child: Option<Box<BinomialNode>>) -> Option<Box<BinomialNode>> {
    let mut rev: Option<Box<BinomialNode>> = None;
    while let Some(mut node) = child.take() {
        child = node.sibling.take();
        node.sibling = rev;
        rev = Some(node);
    }
    rev
}

fn extract_min(heap: Option<Box<BinomialNode>>) -> (Option<usize>, Option<Box<BinomialNode>>) {
    let Some(head) = heap else {
        return (None, None);
    };

    let mut roots = roots_to_vec(Some(head));
    let mut min_i = 0;
    for i in 1..roots.len() {
        if roots[i].key < roots[min_i].key {
            min_i = i;
        }
    }

    let mut min_node = roots.remove(min_i);
    let key = min_node.key;
    let children = reverse_children(min_node.child.take());
    (Some(key), union(vec_to_roots(roots), children))
}

fn binomial_heap_sort(a: &mut [usize]) {
    let mut heap = None;
    for &key in a.iter() {
        heap = insert_key(heap, key);
    }
    for slot in a.iter_mut() {
        let (key, next) = extract_min(heap);
        heap = next;
        *slot = key.expect("binomial heap exhausted early");
    }
}
