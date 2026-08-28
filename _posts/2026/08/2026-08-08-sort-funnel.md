---
title:     ファンネルソートで配列を並び替える
date:      2026-08-08 07:11:55 +0900
tags:      sort
sort_demo: true
---

## ファンネルソートを使用する

ファンネルソート (`funnel sort` / `funnelsort`) は、キャッシュや外部メモリのブロック転送回数を漸近最適に近づけることを目的とした、キャッシュ忘却型（cache-oblivious）の比較ソートである。

通常の[マージソート](/2026/05/03/sort-merge.html)も比較回数は `O(n log n)` だが、二分マージを浅い再帰で繰り返すと、作業集合がキャッシュに収まりきらない段階で転送が膨らみやすい。

ファンネルソートは、だいたい `n^{1/3}` 本の整列済み列をバッファ付きの k 入力マージャ（k-funnel / k-merger）でまとめて併合する形に組み替え、階層メモリを意識したスケジュールをアルゴリズム自体に埋め込む。

本稿のデモと計測コードは簡略化した版である。

1.  **ブロック分割**: 入力長 `n` に対し `k ≈ n^{1/3}`（2 の冪へ切り上げ）を選び、長さおよそ `n/k ≈ n^{2/3}` の連続区間へ分ける。
2.  **再帰整列**: 各ブロックを同じ手続きで整列する。十分小さい区間は挿入ソートへ落とす。
3.  **遅延 k 入力マージャ**: `k` 本の整列済みストリームを、二分マージャの完全二分木で併合する。各内部ノードは出力バッファを持ち、バッファが空（または半分未満）になったときだけ子マージャを再帰的に呼び出して補充する（lazy fill）。
4.  **バッファ寸法**: 部分木の葉数を `m` とするとバッファ容量をおよそ `m^{3/2}`、根ではおよそ `k^3` にとる。空間は `O(k^2)` 級に収まり、`k ≈ n^{1/3}` なら全体で線形の補助領域に抑えられる。

キャッシュサイズ `M` やブロック長 `B` をパラメータに書かない点がキャッシュ忘却の要点である。解析では「キャッシュ容量がブロック長の二乗程度より大きい」（行数がブロック長以上ある）と置くことが多く、そのもとで I/O 複雑さが最適級になることが知られる。CPU 上の壁時計では定数倍と実装の重さが効き、単純なマージソートより速くなるとは限らない。

```pseudocode
procedure fill(v)  // lazy binary merger at node v
  while v.buffer is not full and not v.exhausted
    if v.left.buffer empty and not v.left.exhausted then fill(v.left)
    if v.right.buffer empty and not v.right.exhausted then fill(v.right)
    if both children exhausted then
      v.exhausted = true; return
    move smaller head of the two children into v.buffer

procedure k_merger_merge(streams[0..k))
  build binary merge tree over streams with sized buffers
  while output incomplete
    fill(root)
    drain root.buffer into result

procedure funnel_sort(A)
  n = length(A)
  if n is small then
    insertion_sort(A); return
  k = next_power_of_two(ceil(n^(1/3)))
  split A into k contiguous blocks of size ~ n/k
  for each block B
    funnel_sort(B)
  k_merger_merge(the k sorted blocks)
  copy merged result back into A
```

比較モデルでは時間 `O(n log n)`、空間は再帰とマージャ合わせて `O(n)` 程度。キャッシュ忘却モデルでは、キャッシュがブロック長に対して十分大きいという前提のもとで、ソートの I/O 下界に近い転送回数を狙う。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('funnel-sort-demo', function (root) {
  const INSERTION_LIMIT = 8;

  function rangePairs(lo, hi, role) {
    const pairs = [];
    for (let k = lo; k < hi; k++) {
      pairs.push([k, role]);
    }
    return pairs;
  }

  function cbrtCeil(n) {
    let x = Math.ceil(Math.cbrt(n));
    if (x < 2) {
      x = 2;
    }
    while (x * x * x < n) {
      x += 1;
    }
    return x;
  }

  function nextPow2(x) {
    let p = 2;
    while (p < x) {
      p *= 2;
    }
    return p;
  }

  function bufferCap(leaves) {
    if (leaves <= 1) {
      return 2;
    }
    return Math.max(2, Math.ceil(Math.pow(leaves, 1.5)));
  }

  function insertionSortRange(a, lo, hi, steps) {
    steps.push({
      kind: 'phase',
      text: '挿入ソート: [' + lo + '…' + (hi - 1) + ']',
      lo: lo,
      hi: hi - 1,
      arr: a.slice(),
    });
    for (let i = lo + 1; i < hi; i++) {
      const key = a[i];
      let j = i;
      steps.push({ kind: 'compare', lo: j - 1, hi: j, arr: a.slice() });
      while (j > lo && a[j - 1] > key) {
        a[j] = a[j - 1];
        j -= 1;
        steps.push({ kind: 'write', pos: j, arr: a.slice() });
      }
      a[j] = key;
      if (j !== i) {
        steps.push({ kind: 'write', pos: j, arr: a.slice() });
      }
    }
  }

  function mergeRuns(a, runs, steps) {
    if (runs.length <= 1) {
      return;
    }
    // Read runs from a frozen snapshot so progressive writes do not clobber inputs.
    const source = a.slice();
    const k = nextPow2(Math.max(2, runs.length));
    const nodes = [];
    for (let i = 0; i < k; i++) {
      if (i < runs.length) {
        nodes.push({
          kind: 'leaf',
          lo: runs[i][0],
          hi: runs[i][1],
          pos: runs[i][0],
          exhausted: runs[i][0] >= runs[i][1],
          buf: [],
          head: 0,
          cap: 0,
          left: null,
          right: null,
        });
      } else {
        nodes.push({
          kind: 'leaf',
          lo: 0,
          hi: 0,
          pos: 0,
          exhausted: true,
          buf: [],
          head: 0,
          cap: 0,
          left: null,
          right: null,
        });
      }
    }
    let layer = [];
    let leavesPer = [];
    for (let i = 0; i < k; i++) {
      layer.push(i);
      leavesPer.push(1);
    }
    while (layer.length > 1) {
      const nextLayer = [];
      const nextLeaves = [];
      let i = 0;
      while (i < layer.length) {
        if (i + 1 < layer.length) {
          const left = layer[i];
          const right = layer[i + 1];
          const leaves = leavesPer[i] + leavesPer[i + 1];
          const parent = nodes.length;
          nodes.push({
            kind: 'internal',
            buf: [],
            head: 0,
            cap: bufferCap(leaves),
            left: left,
            right: right,
            exhausted: false,
          });
          nextLayer.push(parent);
          nextLeaves.push(leaves);
          i += 2;
        } else {
          nextLayer.push(layer[i]);
          nextLeaves.push(leavesPer[i]);
          i += 1;
        }
      }
      layer = nextLayer;
      leavesPer = nextLeaves;
    }
    const root = layer[0];
    nodes[root].cap = Math.max(
      nodes[root].cap,
      Math.max(2, Math.ceil(Math.pow(runs.length, 3)))
    );

    function bufLen(node) {
      return node.buf.length - node.head;
    }

    function bufPeek(node) {
      if (node.head >= node.buf.length) {
        return null;
      }
      return node.buf[node.head];
    }

    function bufPop(node) {
      const v = bufPeek(node);
      if (v === null) {
        return null;
      }
      node.head += 1;
      if (node.head === node.buf.length) {
        node.buf = [];
        node.head = 0;
      }
      return v;
    }

    function bufPush(node, v) {
      if (node.head > 0) {
        node.buf = node.buf.slice(node.head);
        node.head = 0;
      }
      node.buf.push(v);
    }

    function leafHas(idx) {
      const n = nodes[idx];
      return !n.exhausted && n.pos < n.hi;
    }

    function displayWithOut(outArr, baseIdx) {
      const d = source.slice();
      for (let t = 0; t < outArr.length; t++) {
        d[baseIdx + t] = outArr[t];
      }
      return d;
    }

    function leafPeek(idx) {
      if (!leafHas(idx)) {
        return null;
      }
      return source[nodes[idx].pos];
    }

    function leafPop(idx) {
      const v = leafPeek(idx);
      if (v === null) {
        return null;
      }
      nodes[idx].pos += 1;
      if (nodes[idx].pos >= nodes[idx].hi) {
        nodes[idx].exhausted = true;
      }
      return v;
    }

    function fill(idx) {
      const node = nodes[idx];
      if (node.kind === 'leaf' || node.exhausted) {
        return;
      }
      while (bufLen(node) < node.cap) {
        const left = node.left;
        const right = node.right;
        if (
          nodes[left].kind === 'internal' &&
          bufLen(nodes[left]) === 0 &&
          !nodes[left].exhausted
        ) {
          fill(left);
        }
        if (
          nodes[right].kind === 'internal' &&
          bufLen(nodes[right]) === 0 &&
          !nodes[right].exhausted
        ) {
          fill(right);
        }
        const leftOk =
          nodes[left].kind === 'leaf' ? leafHas(left) : bufLen(nodes[left]) > 0;
        const rightOk =
          nodes[right].kind === 'leaf'
            ? leafHas(right)
            : bufLen(nodes[right]) > 0;
        if (!leftOk && !rightOk) {
          node.exhausted = true;
          break;
        }
        let takeLeft;
        let li = null;
        let ri = null;
        if (leftOk && rightOk) {
          const lv =
            nodes[left].kind === 'leaf' ? leafPeek(left) : bufPeek(nodes[left]);
          const rv =
            nodes[right].kind === 'leaf'
              ? leafPeek(right)
              : bufPeek(nodes[right]);
          if (nodes[left].kind === 'leaf') {
            li = nodes[left].pos;
          }
          if (nodes[right].kind === 'leaf') {
            ri = nodes[right].pos;
          }
          steps.push({
            kind: 'compare',
            lo: li !== null ? li : runs[0][0],
            hi: ri !== null ? ri : runs[runs.length - 1][1] - 1,
            arr: source.slice(),
          });
          takeLeft = lv <= rv;
        } else {
          takeLeft = leftOk;
        }
        let v;
        if (takeLeft) {
          v =
            nodes[left].kind === 'leaf'
              ? leafPop(left)
              : bufPop(nodes[left]);
        } else {
          v =
            nodes[right].kind === 'leaf'
              ? leafPop(right)
              : bufPop(nodes[right]);
        }
        bufPush(node, v);
      }
    }

    const total = runs.reduce(function (s, r) {
      return s + (r[1] - r[0]);
    }, 0);
    const base = runs[0][0];
    steps.push({
      kind: 'phase',
      text: 'k入力併合（k=' + k + '）: ' + runs.length + ' 本の整列済み列',
      lo: base,
      hi: base + total - 1,
      arr: source.slice(),
    });
    const out = [];
    while (out.length < total) {
      fill(root);
      if (bufLen(nodes[root]) === 0) {
        break;
      }
      while (bufLen(nodes[root]) > 0) {
        const v = bufPop(nodes[root]);
        const writePos = base + out.length;
        out.push(v);
        steps.push({
          kind: 'write',
          pos: writePos,
          arr: displayWithOut(out, base),
        });
      }
      if (nodes[root].exhausted) {
        break;
      }
    }
    for (let t = 0; t < out.length; t++) {
      a[base + t] = out[t];
    }
    steps.push({
      kind: 'phase',
      text: '併合完了: [' + base + '…' + (base + total - 1) + ']',
      lo: base,
      hi: base + total - 1,
      role: 'sorted',
      arr: a.slice(),
    });
  }

  function funnelSortRange(a, lo, hi, steps) {
    const n = hi - lo;
    if (n <= 1) {
      return;
    }
    if (n <= INSERTION_LIMIT) {
      insertionSortRange(a, lo, hi, steps);
      return;
    }
    let k = nextPow2(cbrtCeil(n));
    while (k > n) {
      k = Math.floor(k / 2);
    }
    k = Math.max(2, k);
    const block = Math.ceil(n / k);
    steps.push({
      kind: 'phase',
      text:
        'ブロック分割: n=' +
        n +
        ', k=' +
        k +
        ', ブロック長≈' +
        block +
        '（区間 [' +
        lo +
        '…' +
        (hi - 1) +
        ']）',
      lo: lo,
      hi: hi - 1,
      arr: a.slice(),
    });
    const runs = [];
    let i = lo;
    while (i < hi) {
      const end = Math.min(i + block, hi);
      funnelSortRange(a, i, end, steps);
      if (end > i) {
        runs.push([i, end]);
        steps.push({
          kind: 'phase',
          text: 'ブロック整列済み: [' + i + '…' + (end - 1) + ']',
          lo: i,
          hi: end - 1,
          role: 'sorted',
          arr: a.slice(),
        });
      }
      i = end;
    }
    mergeRuns(a, runs, steps);
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    if (a.length <= 1) {
      steps.push({ kind: 'done', arr: a.slice() });
      return steps;
    }
    funnelSortRange(a, 0, a.length, steps);
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-funnel',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption: 'ファンネルソートのデモ',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'phase') {
        api.mountBars(barsEl, s.arr);
        if (typeof s.lo === 'number' && typeof s.hi === 'number') {
          DemoSort.assignRoles(
            barsEl,
            rangePairs(s.lo, s.hi + 1, s.role || 'range')
          );
        } else {
          DemoSort.clearRoles(barsEl);
        }
        api.setCaption(s.text);
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [
          [s.lo, 'compare'],
          [s.hi, 'compare'],
        ]);
        api.setCaption('比較: 位置 ' + s.lo + ' と ' + s.hi);
        return;
      }
      if (s.kind === 'write') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.pos, 'write']]);
        api.setCaption('書き込み: 位置 ' + s.pos);
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 200,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="funnel-sort-demo"
  data_prefix="funnel"
  script=sort_demo_js
%}

デモでは要素数が少ないため `k` が 2 や 4 程度になり、バッファ寸法の効果は見えにくい。本番の計測コードはより大きい入力で同じ骨格を動かす。

## 類似アルゴリズムとの相違点

[マージソート](/2026/05/03/sort-merge.html)は区間を半分に分け二分マージを重ねる。ファンネルソートはブロック数を `n^{1/3}` 前後に取り、遅延 k 入力マージャのバッファ階層で併合順を制御する点が異なる。

[カスケードマージソート](/2026/06/25/sort-cascade-merge.html)や[ポリフェーズマージソート](/2026/06/26/sort-polyphase-merge.html)は、作業領域の狭め方やテープ本数・ラン分布といった「マージ政策」が主題である。ファンネルソートは I/O（キャッシュミス）回数を漸近項で抑えるデータ配置と呼び出しスケジュールが主題で、外部テープの本数最適化とは別系統である。

[ファンエンデボアスソート](/2026/07/31/sort-van-emde-boas.html)もファンエンデボアスレイアウトと名前が近いが、整数宇宙上の非比較構造であり、比較ベースのキャッシュ忘却マージとは目的が違う。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000019 |        0.000184 |               8 |               8 |
|        512 |        0.000052 |        0.000254 |              10 |              10 |
|       1024 |        0.000105 |        0.000276 |              44 |              44 |
|       2048 |        0.000232 |        0.001097 |              52 |              52 |
|       4096 |        0.000433 |        0.001043 |              68 |              68 |
|       8192 |        0.000944 |        0.001531 |             330 |             330 |
|      16384 |        0.002567 |        0.004277 |             394 |             394 |
|      32768 |        0.005091 |        0.014825 |             522 |             522 |
|      65536 |        0.010403 |        0.016424 |            2583 |            2583 |
|     131072 |        0.023793 |        0.041830 |            3095 |            3095 |
|     262144 |        0.044204 |        0.076452 |            4119 |            4119 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="funnel" %}
