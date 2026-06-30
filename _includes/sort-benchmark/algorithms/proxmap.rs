fn proxmap_sort(a: &mut [usize]) {
    if a.is_empty() {
        return;
    }

    let n = a.len();
    let min = *a.iter().min().unwrap();
    let max = *a.iter().max().unwrap();
    let bucket_count = n;

    let map_key = |x: usize| -> usize {
        if max == min {
            0
        } else {
            ((x - min) * (bucket_count - 1)) / (max - min)
        }
    };

    let mut hit_count = vec![0usize; bucket_count];
    let mut map_keys = Vec::with_capacity(n);

    for &x in a.iter() {
        let mk = map_key(x);
        map_keys.push(mk);
        hit_count[mk] += 1;
    }

    let mut prox_map = vec![None; bucket_count];
    let mut running_total = 0usize;

    for (i, &hits) in hit_count.iter().enumerate() {
        if hits > 0 {
            prox_map[i] = Some(running_total);
            running_total += hits;
        }
    }

    let location: Vec<usize> = map_keys
        .iter()
        .map(|&mk| prox_map[mk].expect("missing prox map entry"))
        .collect();

    let mut a2: Vec<Option<usize>> = vec![None; n];

    for i in 0..n {
        let key = a[i];
        let start = location[i];
        let mut insert_idx = start;

        loop {
            if a2[insert_idx].is_none() {
                a2[insert_idx] = Some(key);
                break;
            }

            let current = a2[insert_idx].unwrap();

            if key < current {
                let mut end = insert_idx + 1;
                while end < n && a2[end].is_some() {
                    end += 1;
                }

                for k in (insert_idx..end - 1).rev() {
                    a2[k + 1] = a2[k];
                }

                a2[insert_idx] = Some(key);
                break;
            }

            insert_idx += 1;
        }
    }

    for i in 0..n {
        a[i] = a2[i].unwrap();
    }
}
