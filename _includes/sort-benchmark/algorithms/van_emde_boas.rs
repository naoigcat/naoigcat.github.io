struct VebTree {
    universe: usize,
    min: Option<usize>,
    max: Option<usize>,
    summary: Option<Box<VebTree>>,
    cluster: Vec<Option<Box<VebTree>>>,
}

fn lower_sqrt(universe: usize) -> usize {
    1usize << (universe.trailing_zeros() / 2)
}

impl VebTree {
    fn new(universe: usize) -> Self {
        debug_assert!(universe.is_power_of_two());
        debug_assert!(universe >= 2);

        if universe == 2 {
            return Self {
                universe,
                min: None,
                max: None,
                summary: None,
                cluster: Vec::new(),
            };
        }

        let lower = lower_sqrt(universe);
        let upper = universe / lower;

        Self {
            universe,
            min: None,
            max: None,
            summary: Some(Box::new(Self::new(upper))),
            cluster: (0..upper).map(|_| None).collect(),
        }
    }

    fn high(&self, x: usize) -> usize {
        x / lower_sqrt(self.universe)
    }

    fn low(&self, x: usize) -> usize {
        x % lower_sqrt(self.universe)
    }

    fn index(&self, high: usize, low: usize) -> usize {
        high * lower_sqrt(self.universe) + low
    }

    fn minimum(&self) -> Option<usize> {
        self.min
    }

    fn maximum(&self) -> Option<usize> {
        self.max
    }

    fn cluster_mut(&mut self, i: usize) -> &mut VebTree {
        let lower = lower_sqrt(self.universe);
        self.cluster[i].get_or_insert_with(|| Box::new(Self::new(lower)))
    }

    fn empty_insert(&mut self, x: usize) {
        self.min = Some(x);
        self.max = Some(x);
    }

    fn insert(&mut self, mut x: usize) {
        if self.min.is_none() {
            self.empty_insert(x);
            return;
        }

        if x < self.min.unwrap() {
            let old_min = self.min.unwrap();
            self.min = Some(x);
            x = old_min;
        }

        if self.universe > 2 {
            let h = self.high(x);
            let l = self.low(x);
            if self.cluster[h]
                .as_ref()
                .and_then(|c| c.minimum())
                .is_none()
            {
                self.summary.as_mut().unwrap().insert(h);
                self.cluster_mut(h).empty_insert(l);
            } else {
                self.cluster_mut(h).insert(l);
            }
        }

        if x > self.max.unwrap() {
            self.max = Some(x);
        }
    }

    fn successor(&self, x: usize) -> Option<usize> {
        if self.universe == 2 {
            return if x == 0 && self.max == Some(1) {
                Some(1)
            } else {
                None
            };
        }

        if let Some(min) = self.min {
            if x < min {
                return Some(min);
            }
        } else {
            return None;
        }

        let h = self.high(x);
        let l = self.low(x);
        let max_low = self.cluster[h].as_ref().and_then(|c| c.maximum());
        if max_low.is_some_and(|m| l < m) {
            let offset = self.cluster[h].as_ref().unwrap().successor(l).unwrap();
            return Some(self.index(h, offset));
        }

        let succ_cluster = self.summary.as_ref().unwrap().successor(h)?;
        let offset = self.cluster[succ_cluster]
            .as_ref()
            .and_then(|c| c.minimum())
            .unwrap();
        Some(self.index(succ_cluster, offset))
    }
}

fn van_emde_boas_sort(a: &mut [usize]) {
    if a.len() <= 1 {
        return;
    }

    let min = *a.iter().min().unwrap();
    let max = *a.iter().max().unwrap();
    let span = max - min + 1;
    let mut count = vec![0usize; span];

    for &x in a.iter() {
        count[x - min] += 1;
    }

    let universe = span.next_power_of_two().max(2);
    let mut tree = VebTree::new(universe);

    for (offset, &c) in count.iter().enumerate() {
        if c > 0 {
            tree.insert(offset);
        }
    }

    let mut idx = 0;
    let mut cur = tree.minimum();
    while let Some(v) = cur {
        let value = min + v;
        for _ in 0..count[v] {
            a[idx] = value;
            idx += 1;
        }
        cur = tree.successor(v);
    }
}
