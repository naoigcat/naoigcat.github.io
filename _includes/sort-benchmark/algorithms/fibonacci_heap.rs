struct FibNode {
    key: usize,
    degree: u32,
    child: Option<Box<FibNode>>,
    sibling: Option<Box<FibNode>>,
}

fn link(mut child: Box<FibNode>, mut parent: Box<FibNode>) -> Box<FibNode> {
    child.sibling = parent.child.take();
    parent.child = Some(child);
    parent.degree += 1;
    parent
}

fn roots_to_vec(mut head: Option<Box<FibNode>>) -> Vec<Box<FibNode>> {
    let mut roots = Vec::new();
    while let Some(mut node) = head.take() {
        head = node.sibling.take();
        roots.push(node);
    }
    roots
}

fn vec_to_roots(roots: Vec<Box<FibNode>>) -> Option<Box<FibNode>> {
    let mut head: Option<Box<FibNode>> = None;
    let mut tail = &mut head;
    for node in roots {
        *tail = Some(node);
        tail = &mut tail.as_mut().unwrap().sibling;
    }
    head
}

fn consolidate(head: Option<Box<FibNode>>) -> Option<Box<FibNode>> {
    let roots = roots_to_vec(head);
    if roots.is_empty() {
        return None;
    }

    let mut degree_table: Vec<Option<Box<FibNode>>> = Vec::new();

    for mut x in roots {
        loop {
            let d = x.degree as usize;
            if d >= degree_table.len() {
                degree_table.resize_with(d + 1, || None);
            }
            if degree_table[d].is_none() {
                degree_table[d] = Some(x);
                break;
            }
            let y = degree_table[d].take().unwrap();
            x = if x.key <= y.key {
                link(y, x)
            } else {
                link(x, y)
            };
        }
    }

    let mut new_roots = Vec::new();
    for slot in degree_table {
        if let Some(node) = slot {
            new_roots.push(node);
        }
    }
    vec_to_roots(new_roots)
}

fn insert_key(heap: Option<Box<FibNode>>, key: usize) -> Option<Box<FibNode>> {
    let mut node = Box::new(FibNode {
        key,
        degree: 0,
        child: None,
        sibling: None,
    });
    node.sibling = heap;
    Some(node)
}

fn extract_min(heap: Option<Box<FibNode>>) -> (Option<usize>, Option<Box<FibNode>>) {
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
    let children = roots_to_vec(min_node.child.take());
    roots.extend(children);
    (Some(key), consolidate(vec_to_roots(roots)))
}

fn fibonacci_heap_sort(a: &mut [usize]) {
    let mut heap = None;
    for &key in a.iter() {
        heap = insert_key(heap, key);
    }
    for slot in a.iter_mut() {
        let (key, next) = extract_min(heap);
        heap = next;
        *slot = key.expect("fibonacci heap exhausted early");
    }
}
