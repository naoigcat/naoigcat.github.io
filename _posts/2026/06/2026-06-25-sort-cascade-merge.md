---
title:     カスケードマージソートで配列を並び替える
date:      2026-06-25 07:09:05 +0900
tags:      sort
sort_demo: true
---

## カスケードマージソートを使用する

カスケードマージソート (`CascadeMergeSort`) は、配列の一部を作業領域として使いながら交換ベースのマージを繰り返すインプレース・マージソートである。

整列済み部分列と作業領域の内容を `swap` で入れ替えながらマージし、作業領域の幅を 1/2 → 1/4 → 1/8 … と段階的に狭めていく（カスケードする）点が名前の由来である。

通常のマージソートが `O(n)` の補助配列を要するのに対し、追加配列を使わず配列内の未整列区間を作業領域として再利用する。最後の数要素は挿入ソートで仕上げる。

1.  **初回分割**: 区間 `[l, u)` を半分に分け、前半 `[l, m)` を再帰整列して結果を後半側の作業領域 `[w, u)`（`w = l + u - m`）へ `wsort` で書き出す。
2.  **カスケード併合**: 作業領域 `[l, w)` に残った未整列部分をさらに半分ずつ整列し、整列済みの右半 `[w, u)` と `wmerge` で併合する。`w` を中央付近へ更新し、作業領域を狭めながら繰り返す。
3.  **交換マージ**: 2 つの昇順部分列 `[i, m)` と `[j, n)` について、先頭同士を比較し、小さい方と作業位置 `w` の要素を交換して確定させる。
4.  **挿入ソート仕上げ**: 作業領域が 2 要素以下になったら、残りの未整列 prefix を右方向へ交換しながら昇順 suffix へ挿入する。

```pseudocode
procedure wmerge(A, i, m, j, n, w)
  while i < m and j < n
    if A[i] <= A[j] then
      swap(A[w], A[i]); w = w + 1; i = i + 1
    else
      swap(A[w], A[j]); w = w + 1; j = j + 1
  copy rest of [i, m) or [j, n) into A[w ..) via swap

procedure wsort(A, l, u, w)
  if u - l > 1 then
    m = floor((l + u) / 2)
    imsort(A, l, m)
    imsort(A, m, u)
    wmerge(A, l, m, m, u, w)
  else
    move A[l] into working slot A[w] by swap

procedure imsort(A, l, u)
  if u - l <= 1 then return
  m = floor((l + u) / 2)
  w = l + u - m
  wsort(A, l, m, w)
  while w - l > 2
    n = w
    w = l + floor((n - l + 1) / 2)
    wsort(A, w, n, l)
    wmerge(A, l, l + n - w, n, u, w)
  for n from w down to l + 1
    bubble A[n - 1] right into sorted suffix [n, u)
```

比較回数は `O(n log n)` に抑えられるが、要素の移動は交換に依存するため定数因子が大きく、補助配列付きマージソートより遅くなりやすい。追加記憶領域は `O(1)`（再帰スタックは別）で、交換の向き次第では等値キーの相対順序を保たない不安定なソートになる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('cascade-merge-sort-demo', function (root) {
  function wmerge(a, i, m, j, n, w, steps) {
    steps.push({
      kind: 'merge_start',
      i: i,
      m: m,
      j: j,
      n: n,
      w: w,
      arr: a.slice(),
    });
    while (i < m && j < n) {
      steps.push({
        kind: 'compare',
        i: i,
        j: j,
        w: w,
        arr: a.slice(),
      });
      if (a[i] <= a[j]) {
        const t = a[w];
        a[w] = a[i];
        a[i] = t;
        steps.push({ kind: 'swap', lo: w, hi: i, arr: a.slice() });
        w += 1;
        i += 1;
      } else {
        const t = a[w];
        a[w] = a[j];
        a[j] = t;
        steps.push({ kind: 'swap', lo: w, hi: j, arr: a.slice() });
        w += 1;
        j += 1;
      }
    }
    while (i < m) {
      const t = a[w];
      a[w] = a[i];
      a[i] = t;
      steps.push({ kind: 'swap', lo: w, hi: i, arr: a.slice() });
      w += 1;
      i += 1;
    }
    while (j < n) {
      const t = a[w];
      a[w] = a[j];
      a[j] = t;
      steps.push({ kind: 'swap', lo: w, hi: j, arr: a.slice() });
      w += 1;
      j += 1;
    }
    steps.push({ kind: 'merge_done', w: w, arr: a.slice() });
  }

  function wsort(a, l, u, w, steps) {
    if (u - l > 1) {
      const mid = l + Math.floor((u - l) / 2);
      steps.push({
        kind: 'wsort_start',
        l: l,
        u: u,
        w: w,
        mid: mid,
        arr: a.slice(),
      });
      imsort(a, l, mid, steps);
      imsort(a, mid, u, steps);
      wmerge(a, l, mid, mid, u, w, steps);
    } else {
      while (l < u) {
        const t = a[l];
        a[l] = a[w];
        a[w] = t;
        steps.push({ kind: 'swap', lo: l, hi: w, arr: a.slice() });
        l += 1;
        w += 1;
      }
    }
  }

  function imsort(a, l, u, steps) {
    if (u - l <= 1) {
      return;
    }
    const mid = l + Math.floor((u - l) / 2);
    let w = l + u - mid;
    steps.push({
      kind: 'cascade_start',
      l: l,
      u: u,
      w: w,
      arr: a.slice(),
    });
    wsort(a, l, mid, w, steps);
    while (w - l > 2) {
      const n = w;
      w = l + Math.floor((n - l + 1) / 2);
      steps.push({
        kind: 'cascade_step',
        l: l,
        u: u,
        w: w,
        n: n,
        arr: a.slice(),
      });
      wsort(a, w, n, l, steps);
      wmerge(a, l, l + n - w, n, u, w, steps);
    }
    let n = w;
    while (n > l) {
      steps.push({
        kind: 'insert_start',
        pos: n - 1,
        l: l,
        u: u,
        arr: a.slice(),
      });
      let mIdx = n;
      while (mIdx < u && a[mIdx] < a[mIdx - 1]) {
        const t = a[mIdx];
        a[mIdx] = a[mIdx - 1];
        a[mIdx - 1] = t;
        steps.push({ kind: 'swap', lo: mIdx - 1, hi: mIdx, arr: a.slice() });
        mIdx += 1;
      }
      n -= 1;
    }
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    if (a.length <= 1) {
      steps.push({ kind: 'done', arr: a.slice() });
      return steps;
    }
    imsort(a, 0, a.length, steps);
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  function rangePairs(lo, hi, role) {
    const pairs = [];
    for (let k = lo; k < hi; k++) {
      pairs.push([k, role]);
    }
    return pairs;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-cascade-merge',
    initialValues: [8, 3, 12, 1, 6, 14, 2, 15, 5, 11, 9, 4, 13, 7, 10, 0],
    initialCaption:
      'カスケードマージソートのデモ（作業領域は紫、比較はオレンジ、交換は緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'cascade_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.l, s.u, 'range'));
        DemoSort.assignRoles(barsEl, rangePairs(s.w, s.u, 'pivot'));
        api.setCaption(
          '初回 wsort: 前半 [' +
            s.l +
            '…' +
            (s.w - 1) +
            '] を整列し、作業領域 [' +
            s.w +
            '…' +
            (s.u - 1) +
            '] へ書き出す'
        );
        return;
      }
      if (s.kind === 'cascade_step') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.l, s.u, 'range'));
        DemoSort.assignRoles(barsEl, rangePairs(s.l, s.w, 'pivot'));
        api.setCaption(
          'カスケード段: 作業領域 [' +
            s.l +
            '…' +
            (s.w - 1) +
            '] を整列し [' +
            s.w +
            '…' +
            (s.u - 1) +
            '] と併合'
        );
        return;
      }
      if (s.kind === 'wsort_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.l, s.u, 'range'));
        api.setCaption(
          'wsort: [' + s.l + '…' + (s.u - 1) + '] → 作業領域 w = ' + s.w
        );
        return;
      }
      if (s.kind === 'merge_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.i, s.n, 'range'));
        DemoSort.assignRoles(barsEl, [[s.w, 'write']]);
        api.setCaption(
          'wmerge: 左 [' +
            s.i +
            '…' +
            (s.m - 1) +
            '] と 右 [' +
            s.j +
            '…' +
            (s.n - 1) +
            '] を w = ' +
            s.w +
            ' から確定'
        );
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.i, 'compare'], [s.j, 'compare'], [s.w, 'write']]);
        api.setCaption(
          '比較: 位置 ' + s.i + ' と ' + s.j + '（確定先 w = ' + s.w + '）'
        );
        return;
      }
      if (s.kind === 'swap') {
        DemoSort.assignRoles(barsEl, [[s.lo, 'swap'], [s.hi, 'swap']]);
        api.setCaption('交換しています…');
        await DemoSort.flipSwap(barsEl, s.lo, s.hi);
        DemoSort.clearRoles(barsEl);
        api.setCaption('交換しました（位置 ' + s.lo + ' と ' + s.hi + '）');
        return;
      }
      if (s.kind === 'merge_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('wmerge が完了（次の確定位置 w = ' + s.w + '）');
        return;
      }
      if (s.kind === 'insert_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.pos, 'insert']]);
        api.setCaption(
          '挿入ソート仕上げ: 位置 ' + s.pos + ' を右方向へ挿入'
        );
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 260,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="cascade-merge-sort-demo"
  data_prefix="cascade-merge"
  script=sort_demo_js
%}

補助配列を使わない代わりに交換回数が増え、キャッシュ効率も通常のマージソートに劣りやすい。外部記憶向けのカスケードマージ（多段テープ併合）とは目的が異なり、ここでは主記憶上のインプレース整列を指す。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000008 |        0.000445 |            1662 |            1668 |
|        512 |        0.000019 |        0.000666 |            1666 |            1672 |
|       1024 |        0.000044 |        0.000494 |            1674 |            1680 |
|       2048 |        0.000095 |        0.000438 |            1690 |            1696 |
|       4096 |        0.000212 |        0.000707 |            1721 |            1728 |
|       8192 |        0.000473 |        0.000777 |            1785 |            1792 |
|      16384 |        0.001023 |        0.001249 |            1918 |            1924 |
|      32768 |        0.002249 |        0.004620 |            2177 |            2184 |
|      65536 |        0.005162 |        0.016857 |            2689 |            2696 |
|     131072 |        0.010093 |        0.014215 |            3714 |            3720 |
|     262144 |        0.021324 |        0.152617 |            5762 |            5768 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="cascade_merge" %}
