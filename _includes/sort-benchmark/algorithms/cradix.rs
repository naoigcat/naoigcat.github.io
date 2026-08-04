const RADIX: usize = 10;
const BS: usize = 2;

fn digit_width(max: usize) -> usize {
    if max == 0 {
        return 1;
    }
    let mut w = 0usize;
    let mut v = max;
    while v > 0 {
        w += 1;
        v /= RADIX;
    }
    w
}

fn digit_at(value: usize, pos: usize, width: usize) -> u8 {
    let power = width - 1 - pos;
    let mut div = 1usize;
    for _ in 0..power {
        div = div.saturating_mul(RADIX);
    }
    ((value / div) % RADIX) as u8
}

fn fill_buffer(value: usize, start: usize, width: usize) -> [u8; BS] {
    let mut buf = [0u8; BS];
    for i in 0..BS {
        if start + i < width {
            buf[i] = digit_at(value, start + i, width);
        }
    }
    buf
}

fn cradix_rec(a: &mut [usize], buffers: &mut [[u8; BS]], digit_pos: usize, width: usize) {
    let n = a.len();
    if n <= 1 || digit_pos >= width {
        return;
    }

    let mut count = [0usize; RADIX];
    for b in buffers.iter() {
        count[b[0] as usize] += 1;
    }

    let mut offset = [0usize; RADIX];
    for i in 1..RADIX {
        offset[i] = offset[i - 1] + count[i - 1];
    }

    let mut out_a = vec![0usize; n];
    let mut out_b = vec![[0u8; BS]; n];
    let mut cursor = offset;
    for i in 0..n {
        let d = buffers[i][0] as usize;
        out_a[cursor[d]] = a[i];
        out_b[cursor[d]] = buffers[i];
        cursor[d] += 1;
    }
    a.copy_from_slice(&out_a);
    buffers.copy_from_slice(&out_b);

    for r in 0..RADIX {
        let start = offset[r];
        let len = count[r];
        if len <= 1 {
            continue;
        }
        let next_pos = digit_pos + 1;
        if next_pos >= width {
            continue;
        }

        let end = start + len;
        for i in start..end {
            for j in 0..BS - 1 {
                buffers[i][j] = buffers[i][j + 1];
            }
            buffers[i][BS - 1] = 0;
        }

        if next_pos % BS == 0 {
            for i in start..end {
                buffers[i] = fill_buffer(a[i], next_pos, width);
            }
        }

        cradix_rec(
            &mut a[start..end],
            &mut buffers[start..end],
            next_pos,
            width,
        );
    }
}

fn cradix_sort(a: &mut [usize]) {
    if a.is_empty() {
        return;
    }

    let max = *a.iter().max().unwrap();
    let width = digit_width(max);
    let n = a.len();
    let mut buffers = vec![[0u8; BS]; n];
    for i in 0..n {
        buffers[i] = fill_buffer(a[i], 0, width);
    }
    cradix_rec(a, &mut buffers, 0, width);
}
