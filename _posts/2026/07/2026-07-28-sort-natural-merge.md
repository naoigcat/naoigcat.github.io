---
title:     ナチュラルマージソートで配列を並び替える
date:      2026-07-28 06:59:57 +0900
tags:      sort
sort_demo: true
---

## ナチュラルマージソートを使用する

ナチュラルマージソート (`natural merge sort`) は、入力にすでに存在する昇順の連続区間（自然ラン）を検出し、隣接するラン同士をマージソートと同じ要領で併合していく。

通常のボトムアップ型マージソートが長さ 1 のランから機械的に倍々で併合するのに対し、最初から「すでに整っている部分」をランとして取り込む点が名前の由来である。

1.  **ランの検出**: 配列を左から走査し、隣接要素が非減少（`A[i] <= A[i+1]`）であるあいだは同じランとして伸ばす。降順に落ちたところで区切り、次のランを始める。
2.  **ペア併合**: 見つかったランが 2 本以上なら、隣接する 2 本ずつを先頭からペアにしてマージする。奇数本目の末尾ランは次のパスまで持ち越す。
3.  **繰り返し**: マージ後の配列を再び走査し、ランが 1 本になるまで手順 1〜2 を繰り返す。ランが 1 本になった時点で全体が昇順である。

パスのたびにランを再検出するため、併合の境界でたまたま非減少がつながれば、次パスではより長いランとして扱われる。

```pseudocode
procedure natural_merge_sort(A)
  n = length(A)
  if n <= 1 then
    return
  loop
    runs = empty list of (start, end)  // half-open [start, end)
    i = 0
    while i < n
      start = i
      i = i + 1
      while i < n and A[i - 1] <= A[i]
        i = i + 1
      append (start, i) to runs
    if length(runs) <= 1 then
      return
    k = 0
    while k + 1 < length(runs)
      (lo, mid) = runs[k]
      (_, hi) = runs[k + 1]
      merge(A, lo, mid, hi)  // stable two-way merge into A[lo .. hi)
      k = k + 2
```

整列済み入力では最初の走査でランが 1 本だけになり `O(n)` で終わる。ランダム入力ではラン数が多く、最悪計算量は通常のマージソートと同様に `O(n log n)` である。マージを安定実装すれば安定ソートになる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('natural-merge-sort-demo', function (root) {
  function buildDisplay(a, lo, tmp) {
    const d = a.slice();
    for (let t = 0; t < tmp.length; t++) {
      d[lo + t] = tmp[t];
    }
    return d;
  }

  function rangePairs(lo, hi, role) {
    const pairs = [];
    for (let k = lo; k <= hi; k++) {
      pairs.push([k, role]);
    }
    return pairs;
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;

    function merge(lo, mid, hi) {
      steps.push({ kind: 'merge_start', lo: lo, mid: mid, hi: hi, arr: a.slice() });
      const tmp = [];
      let i = lo;
      let j = mid;
      while (i < mid && j < hi) {
        steps.push({
          kind: 'merge_compare',
          lo: lo,
          mid: mid,
          hi: hi,
          i: i,
          j: j,
          arr: buildDisplay(a, lo, tmp),
        });
        if (a[i] <= a[j]) {
          tmp.push(a[i]);
          i++;
        } else {
          tmp.push(a[j]);
          j++;
        }
        steps.push({
          kind: 'merge_write',
          lo: lo,
          hi: hi,
          writePos: lo + tmp.length - 1,
          arr: buildDisplay(a, lo, tmp),
        });
      }
      while (i < mid) {
        tmp.push(a[i]);
        i++;
        steps.push({
          kind: 'merge_write',
          lo: lo,
          hi: hi,
          writePos: lo + tmp.length - 1,
          arr: buildDisplay(a, lo, tmp),
        });
      }
      while (j < hi) {
        tmp.push(a[j]);
        j++;
        steps.push({
          kind: 'merge_write',
          lo: lo,
          hi: hi,
          writePos: lo + tmp.length - 1,
          arr: buildDisplay(a, lo, tmp),
        });
      }
      for (let t = 0; t < tmp.length; t++) {
        a[lo + t] = tmp[t];
      }
      steps.push({ kind: 'merge_done', lo: lo, hi: hi, arr: a.slice() });
    }

    if (n === 0) {
      steps.push({ kind: 'done', arr: [] });
      return steps;
    }

    for (;;) {
      const runs = [];
      let i = 0;
      while (i < n) {
        const start = i;
        i += 1;
        while (i < n && a[i - 1] <= a[i]) {
          i += 1;
        }
        runs.push([start, i]);
        steps.push({
          kind: 'run_found',
          lo: start,
          hi: i - 1,
          arr: a.slice(),
        });
      }
      steps.push({
        kind: 'pass_runs',
        runs: runs.map(function (r) {
          return { lo: r[0], hi: r[1] - 1 };
        }),
        arr: a.slice(),
      });
      if (runs.length <= 1) {
        break;
      }
      let k = 0;
      while (k + 1 < runs.length) {
        const lo = runs[k][0];
        const mid = runs[k][1];
        const hi = runs[k + 1][1];
        merge(lo, mid, hi);
        k += 2;
      }
      if (runs.length % 2 === 1) {
        const last = runs[runs.length - 1];
        steps.push({
          kind: 'run_carry',
          lo: last[0],
          hi: last[1] - 1,
          arr: a.slice(),
        });
      }
    }

    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-natural-merge',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'ナチュラルマージソートのデモ（青＝検出したラン／マージ対象、比較はオレンジ、確定書き込みは緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'run_found') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'range'));
        api.setCaption('自然ランを検出: 位置 ' + s.lo + ' … ' + s.hi);
        return;
      }
      if (s.kind === 'pass_runs') {
        api.mountBars(barsEl, s.arr);
        const pairs = [];
        for (let r = 0; r < s.runs.length; r++) {
          const run = s.runs[r];
          for (let k = run.lo; k <= run.hi; k++) {
            pairs.push([k, 'range']);
          }
        }
        DemoSort.assignRoles(barsEl, pairs);
        api.setCaption(
          'このパスのラン数は ' + s.runs.length + ' 本（1 本なら整列完了）'
        );
        return;
      }
      if (s.kind === 'run_carry') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'sorted'));
        api.setCaption(
          '奇数本目の末尾ラン ' + s.lo + ' … ' + s.hi + ' は次パスへ持ち越し'
        );
        return;
      }
      if (s.kind === 'merge_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi - 1, 'range'));
        api.setCaption(
          'マージ開始: 左 [' +
            s.lo +
            '…' +
            (s.mid - 1) +
            '] と 右 [' +
            s.mid +
            '…' +
            (s.hi - 1) +
            ']'
        );
        return;
      }
      if (s.kind === 'merge_compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.i, 'compare'], [s.j, 'compare']]);
        api.setCaption('比較: 位置 ' + s.i + ' と ' + s.j);
        return;
      }
      if (s.kind === 'merge_write') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.writePos, 'write']]);
        api.setCaption('先頭から確定: 位置 ' + s.writePos);
        return;
      }
      if (s.kind === 'merge_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '区間 ' + s.lo + ' … ' + (s.hi - 1) + ' のマージが完了しました'
        );
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 220,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="natural-merge-sort-demo"
  data_prefix="natural-merge"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[マージソート](/2026/05/03/sort-merge.html)は分割位置を中央で固定するため、入力の既存順序を活かさない。ナチュラル・マージは自然ランから始める分、整列済みや部分的に整った入力でパス数を減らせる。

[ティムソート](/2026/05/23/sort-tim.html)や[パワーソート](/2026/05/24/sort-power.html)は、降順ランの反転・短いランの挿入ソート拡張・スタック上のマージ抑制など、自然ラン活用をさらに洗練した実用実装である。本記事の手続きは、その原型にあたる単純な自然ラン＋ペア併合に絞っている。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000026 |        0.002400 |              70 |              80 |
|        512 |        0.000049 |        0.000311 |              76 |              84 |
|       1024 |        0.000104 |        0.000445 |              84 |              92 |
|       2048 |        0.000212 |        0.000776 |              99 |             116 |
|       4096 |        0.000422 |        0.001911 |             125 |             148 |
|       8192 |        0.000862 |        0.002831 |             181 |             196 |
|      16384 |        0.001847 |        0.004077 |             281 |             332 |
|      32768 |        0.003790 |        0.008569 |             474 |             576 |
|      65536 |        0.007729 |        0.041187 |             938 |            1096 |
|     131072 |        0.015961 |        0.042356 |            1843 |            2116 |
|     262144 |        0.033838 |        0.067317 |            3641 |            4172 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="natural_merge" %}
