const LEONARDO: [usize; 46] = [
    1, 1, 3, 5, 9, 15, 25, 41, 67, 109, 177, 287, 465, 753, 1219, 1973, 3193,
    5167, 8361, 13529, 21891, 35421, 57313, 92735, 150049, 242785, 392835,
    635621, 1028457, 1664079, 2692537, 4356617, 7049155, 11405773, 18454929,
    29860703, 48315633, 78176337, 126491971, 204668309, 331160281, 535828591,
    866988873, 1402817465, 2269806339, 3672623805,
];

fn smooth_sift_in(a: &mut [usize], root_idx: usize, size: usize) {
    if size < 2 {
        return;
    }
    let tmp = a[root_idx];
    let mut root = root_idx;
    let mut sz = size;
    loop {
        let right = root - 1;
        let left = right - LEONARDO[sz - 2];
        let (next, next_size) = if a[right] < a[left] {
            (left, sz - 1)
        } else {
            (right, sz - 2)
        };
        if a[next] <= tmp {
            break;
        }
        a[root] = a[next];
        root = next;
        sz = next_size;
        if sz <= 1 {
            break;
        }
    }
    a[root] = tmp;
}

fn smooth_interheap_sift(a: &mut [usize], root_idx: usize, mask: usize, offset: usize) {
    let tmp = a[root_idx];
    let mut root = root_idx;
    let mut hmask = mask;
    let mut hoffset = offset;
    while hmask != 1 {
        let mut max = tmp;
        if hoffset > 1 {
            let right = root - 1;
            let left = right - LEONARDO[hoffset - 2];
            max = max.max(a[left]).max(a[right]);
        }
        let next = root - LEONARDO[hoffset];
        if a[next] <= max {
            break;
        }
        a[root] = a[next];
        root = next;
        loop {
            hmask >>= 1;
            hoffset += 1;
            if hmask & 1 != 0 {
                break;
            }
        }
    }
    a[root] = tmp;
    smooth_sift_in(a, root, hoffset);
}

fn smooth_sort(a: &mut [usize]) {
    let n = a.len();
    if n <= 1 {
        return;
    }
    let mut mask = 1usize;
    let mut offset = 1usize;
    for i in 1..n {
        if mask & 2 != 0 {
            mask = (mask >> 2) | 1;
            offset += 2;
        } else if offset == 1 {
            mask = (mask << 1) | 1;
            offset = 0;
        } else {
            mask = (mask << (offset - 1)) | 1;
            offset = 1;
        }
        let wide_bottom =
            (mask & 2 != 0 && i + 1 < n)
                || (offset > 0 && 1 + i + LEONARDO[offset - 1] < n);
        if wide_bottom {
            smooth_sift_in(a, i, offset);
        } else {
            smooth_interheap_sift(a, i, mask, offset);
        }
    }
    for i in (2..n).rev() {
        if offset < 2 {
            loop {
                mask >>= 1;
                offset += 1;
                if mask & 1 != 0 {
                    break;
                }
            }
        } else {
            let ch1 = i - 1;
            let ch0 = ch1 - LEONARDO[offset - 2];
            mask &= !1;
            for ch in [ch0, ch1] {
                mask = (mask << 1) | 1;
                offset -= 1;
                smooth_interheap_sift(a, ch, mask, offset);
            }
        }
    }
}
