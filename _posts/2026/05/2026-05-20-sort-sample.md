---
title:     サンプルソートで配列を並び替える
date:      2026-05-20 06:24:32 +0900
tags:      sort
sort_demo: true
---

## サンプルソートを使用する

サンプルソート (`sample sort`) は、入力から **少数の標本（サンプル）** を取り出して整列し、その値を **分割点（スプリッター）** として全体を **バケット（区間）** に分け、
各バケットを独立に整列してから連結する比較ソートである。並列計算向けに設計された手法として知られ、プロセッサ数 p に対して **p−1 個のスプリッター** を選ぶ構成が典型である。

クイックソートが **1 つのピボット** で左右に分けるのに対し、サンプルソートは **複数のスプリッター** で **p 個（デモでは要素数に応じた複数個）のバケット** に一度に仕分ける。分割の偏りを抑えやすく、各バケットを **別プロセッサで同時に** 整列できる点が並列版の利点である。

1.  **サンプリング**: 配列から s 個の要素を（等間隔に）選び、サンプル集合を得る。文献では s ≈ √n や s = p−1 などが用いられる。
2.  **サンプルの整列**: サンプルだけを整列し、昇順のスプリッター列 t₀ ≤ t₁ ≤ … を得る。
3.  **仕分け**: 各要素 x を、t₀, t₁, … と比較して属するバケット番号を決める（例: x ≤ t₀ ならバケット 0、t₀ < x ≤ t₁ ならバケット 1、…）。
4.  **バケット整列**: 各バケットを独立に整列する（再帰的にサンプルソート、または十分小さければ挿入ソートなど）。
5.  **連結**: バケット 0, 1, … の順に並べれば全体が昇順になる。

```pseudocode
procedure sample_sort(A, s)
  if length(A) <= SMALL then
    insertion_sort(A)
    return
  S = choose_s_samples(A, s)
  sort(S)
  splitters = S
  buckets = empty list of s + 1 arrays
  for each x in A
    b = bucket_index(x, splitters)
    append x to buckets[b]
  for each bucket B in buckets
    sample_sort(B, s)
  A = concatenate(buckets)
```

並列モデルではステップ 3〜4 を各バケットごとに同時実行でき、要素数 n・プロセッサ数 p が釣り合うとき **O(n/p) 程度の並列時間** を狙える。
逐次実行に落とすと、再帰の深さとバケットサイズのバランス次第だが、比較回数は **O(n log n)** オーダーに収まる設計が一般的である。
追加メモリはバケット用バッファ分 **O(n)** になりやすい。**安定ソートではない** 実装が多い（仕分けとバケット内ソートで等値の順序が入れ替わりうる）。

比例拡張ソート（PESort）のように「小さな整列済み標本から分割点を得る」発想はサンプルソートと共通する。バブルソートのように隣接交換だけで進む単純ソートや、クイックソートの **単一ピボット再帰** と比べると、**標本に基づく多分割** と **並列化しやすい区切り** が特徴的である。

以下のデモでは **15 要素から 4 個のサンプル** を取り、スプリッター 4 個で **5 バケット** に仕分けたあと、各バケットを挿入ソートで仕上げる。紫枠はスプリッター（整列済みサンプル）、オレンジは比較、緑は交換を表す。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('sample-sort-demo', function (root) {
  const SAMPLE_COUNT = 4;

  function pickSampleIndices(n, s) {
    const indices = [];
    const seen = {};
    for (let i = 0; i < s; i++) {
      const idx = Math.floor((i * (n - 1)) / Math.max(s - 1, 1));
      if (!seen[idx]) {
        seen[idx] = true;
        indices.push(idx);
      }
    }
    return indices;
  }

  function bucketIndex(x, splitters) {
    let b = 0;
    while (b < splitters.length && x > splitters[b]) {
      b++;
    }
    return b;
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const n = a.length;
    const sampleIdx = pickSampleIndices(n, SAMPLE_COUNT);
    const steps = [];

    steps.push({
      kind: 'phase',
      text:
        'サンプルソート: 等間隔に ' +
        SAMPLE_COUNT +
        ' 個の標本を選び、スプリッターとして使う',
      arr: a.slice(),
    });

    steps.push({
      kind: 'sample_pick',
      indices: sampleIdx.slice(),
      arr: a.slice(),
    });

    for (let i = 1; i < sampleIdx.length; i++) {
      let j = i;
      while (j > 0) {
        const loIdx = sampleIdx[j - 1];
        const hiIdx = sampleIdx[j];
        steps.push({
          kind: 'sample_compare',
          lo: loIdx,
          hi: hiIdx,
          arr: a.slice(),
        });
        if (a[loIdx] > a[hiIdx]) {
          const t = a[loIdx];
          a[loIdx] = a[hiIdx];
          a[hiIdx] = t;
          steps.push({
            kind: 'sample_swap',
            lo: loIdx,
            hi: hiIdx,
            arr: a.slice(),
          });
          j--;
        } else {
          break;
        }
      }
    }

    const splitters = sampleIdx.map(function (idx) {
      return a[idx];
    });
    const splitterPositions = sampleIdx.slice();

    steps.push({
      kind: 'splitters',
      values: splitters.slice(),
      positions: splitterPositions.slice(),
      arr: a.slice(),
    });

    const bucketCount = splitters.length + 1;
    const buckets = [];
    let b;
    for (b = 0; b < bucketCount; b++) {
      buckets.push([]);
    }

    for (let i = 0; i < n; i++) {
      const v = a[i];
      steps.push({
        kind: 'assign_scan',
        idx: i,
        arr: a.slice(),
        splitters: splitters.slice(),
        positions: splitterPositions.slice(),
      });
      let cmp = 0;
      while (cmp < splitters.length) {
        steps.push({
          kind: 'assign_compare',
          idx: i,
          splitter: cmp,
          lo: i,
          hi: splitterPositions[cmp],
          arr: a.slice(),
        });
        if (v > splitters[cmp]) {
          cmp++;
        } else {
          break;
        }
      }
      const bucket = cmp;
      buckets[bucket].push(v);
      steps.push({
        kind: 'assign_done',
        idx: i,
        bucket: bucket,
        arr: a.slice(),
      });
    }

    const gathered = [];
    for (b = 0; b < bucketCount; b++) {
      gathered.push.apply(gathered, buckets[b]);
    }
    for (let i = 0; i < n; i++) {
      a[i] = gathered[i];
    }
    steps.push({ kind: 'gather', arr: a.slice() });

    let pos = 0;
    for (b = 0; b < bucketCount; b++) {
      const len = buckets[b].length;
      if (len <= 1) {
        pos += len;
        continue;
      }
      const lo = pos;
      const hi = pos + len - 1;
      steps.push({
        kind: 'bucket_start',
        lo: lo,
        hi: hi,
        bucket: b,
        arr: a.slice(),
      });
      for (let i = lo + 1; i <= hi; i++) {
        let j = i;
        while (j > lo) {
          steps.push({
            kind: 'compare',
            lo: j - 1,
            hi: j,
            arr: a.slice(),
          });
          if (a[j - 1] > a[j]) {
            const t2 = a[j - 1];
            a[j - 1] = a[j];
            a[j] = t2;
            steps.push({
              kind: 'swap',
              lo: j - 1,
              hi: j,
              arr: a.slice(),
            });
            j--;
          } else {
            break;
          }
        }
      }
      steps.push({
        kind: 'bucket_done',
        lo: lo,
        hi: hi,
        bucket: b,
        arr: a.slice(),
      });
      pos += len;
    }

    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-sample',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'サンプルソートのデモ（紫はスプリッター、オレンジは比較、緑は交換）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'phase') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(s.text);
        return;
      }
      if (s.kind === 'sample_pick') {
        api.mountBars(barsEl, s.arr);
        const roles = s.indices.map(function (idx) {
          return [idx, 'compare'];
        });
        DemoSort.assignRoles(barsEl, roles);
        api.setCaption(
          'サンプリング: 位置 ' + s.indices.join('、') + ' を標本として選ぶ'
        );
        return;
      }
      if (s.kind === 'sample_compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'compare']]);
        api.setCaption(
          '標本の整列: 位置 ' + s.lo + ' と ' + s.hi + ' を比較'
        );
        return;
      }
      if (s.kind === 'sample_swap') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.hi, 'swap']]);
        api.setCaption('標本同士を交換しています…');
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '交換しました（位置 ' + s.lo + ' と ' + s.hi + '）'
        );
        return;
      }
      if (s.kind === 'splitters') {
        api.mountBars(barsEl, s.arr);
        const pivotRoles = s.positions.map(function (idx) {
          return [idx, 'pivot'];
        });
        DemoSort.assignRoles(barsEl, pivotRoles);
        api.setCaption(
          'スプリッター確定: ' +
            s.values.join(' ≤ ') +
            '（位置 ' +
            s.positions.join('、') +
            '）'
        );
        return;
      }
      if (s.kind === 'assign_scan') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.idx, 'compare']]);
        api.setCaption(
          '仕分け: 位置 ' +
            s.idx +
            ' の値 ' +
            s.arr[s.idx] +
            ' をスプリッターと比較'
        );
        return;
      }
      if (s.kind === 'assign_compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'pivot']]);
        api.setCaption(
          '位置 ' +
            s.idx +
            ' の値とスプリッター ' +
            s.arr[s.hi] +
            '（位置 ' +
            s.hi +
            '）を比較'
        );
        return;
      }
      if (s.kind === 'assign_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '位置 ' + s.idx + ' の値はバケット ' + s.bucket + ' へ'
        );
        return;
      }
      if (s.kind === 'gather') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('バケットを左から順に連結し、配列へ書き戻す');
        return;
      }
      if (s.kind === 'bucket_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'range'], [s.hi, 'range']]);
        api.setCaption(
          'バケット ' +
            s.bucket +
            ' を挿入ソート: 位置 ' +
            s.lo +
            ' … ' +
            s.hi
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'compare']]);
        api.setCaption('比較: 位置 ' + s.lo + ' と ' + s.hi);
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.hi, 'swap']]);
        api.setCaption('交換しています…');
        await DemoSort.flipAdjacentSwap(barsEl, s.lo);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '交換しました（位置 ' + s.lo + ' と ' + (s.lo + 1) + '）'
        );
        return;
      }
      if (s.kind === 'bucket_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          'バケット ' + s.bucket + ' の整列が完了（位置 ' + s.lo + ' … ' + s.hi + '）'
        );
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 280,
  });
});
</script>
{% endcapture %}

{% include sort-demo/wrapper.html
  id="sample-sort-demo"
  data_prefix="sample"
  script=sort_demo_js
%}

外部ソートや分散整列の文脈では、サンプルソートは **I/O 効率のよい分割** としても使われる。実装ではサンプル数、再帰の打ち切り、等値要素の扱い（3-way 分割など）が性能を左右するため、クイックソート単体より **パラメータとメモリ使用量** の設計が重要になる。
