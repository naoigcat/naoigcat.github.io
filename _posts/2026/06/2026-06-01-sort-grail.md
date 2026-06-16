---
title:     グレイルソートで配列を並び替える
date:      2026-06-01 20:11:29 +0900
tags:      sort
sort_demo: true
---

## グレイルソートを使用する

グレイルソート (`Grailsort`) はウィキソートと同じブロックマージソートだが、内部バッファの代わりに先頭の一意なキーを使用する。

定数追加空間での高速安定マージ・整列に基づく発想を取り入れ、安定かつ最悪 `O(n log n)` で、追加記憶領域を `O(1)`（固定サイズの外部バッファを使う変種ではスタック上の `512` 要素程度）に抑えている。

1.  **キー収集**: 配列から `2√n` 個程度の互いに異なる値を探し、回転（rotate）で先頭へ集める。一意な値が足りない場合は、回転ベースの安定マージ（Lazy Stable Sort）にフォールバックする。
2.  **ブロック構築**: 収集したキーの半分を内部バッファとし、ボトムアップで小さな整列済みランを倍々にマージしていく。
3.  **ブロック併合**: ランがバッファに収まらなくなると、長さ `√n` 程度のブロックに分割し、残り半分のキーで A/B ストリームを識別しながらインプレースで位置を決める。
4.  **キーの復元**: 最後に先頭へ退避したキー列を挿入ソートし、全体へマージして整列を完了する。

```pseudocode
procedure grail_sort(A)
  if length(A) < 16 then
    insertion_sort(A)
    return
  keys = collect_unique_keys(A, about 2 * sqrt(length(A)))
  if not enough keys then
    lazy_stable_sort(A)   // rotation-based in-place merge
    return
  buffer = first half of keys
  build_sorted_runs_bottom_up(A, buffer)
  while run_length < length(A)
    combine_blocks_in_place(A, buffer, keys)
    run_length = run_length * 2
  insertion_sort(keys)
  merge keys back into A
```

実装は回転・ブロック操作・キー管理が絡み、コード量はマージソート単体より大きくなる。計測コードでは512要素の固定バッファを使う `GrailSortWithBuffer` 相当の実装を用いる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('grail-sort-demo', function (root) {
  const RUN_SIZE = 4;
  const KEY_TARGET = 4;

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

  function collectKeys(a, steps) {
    const keys = [];
    const keyPos = [];
    for (let u = 0; u < a.length && keys.length < KEY_TARGET; u++) {
      if (keys.indexOf(a[u]) === -1) {
        keys.push(a[u]);
        keyPos.push(u);
        steps.push({
          kind: 'key_found',
          pos: u,
          value: a[u],
          keyCount: keys.length,
          arr: a.slice(),
        });
      }
    }
    return { keys: keys, keyPos: keyPos };
  }

  function insertionSortRange(a, lo, hi, steps) {
    for (let i = lo + 1; i <= hi; i++) {
      const key = a[i];
      let j = i;
      steps.push({ kind: 'run_compare', lo: j - 1, hi: j, arr: a.slice() });
      while (j > lo && a[j - 1] > key) {
        a[j] = a[j - 1];
        j--;
        steps.push({ kind: 'run_shift', pos: j, arr: a.slice() });
      }
      a[j] = key;
      if (j !== i) {
        steps.push({ kind: 'run_write', pos: j, arr: a.slice() });
      }
    }
  }

  function mergeRange(a, lo, mid, hi, steps) {
    steps.push({ kind: 'merge_start', lo: lo, mid: mid, hi: hi, arr: a.slice() });
    const tmp = [];
    let i = lo;
    let j = mid + 1;
    while (i <= mid && j <= hi) {
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
    while (i <= mid) {
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
    while (j <= hi) {
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

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    const n = a.length;
    if (n === 0) {
      steps.push({ kind: 'done', arr: a.slice() });
      return steps;
    }

    steps.push({
      kind: 'phase',
      text: 'キー収集: 一意な値を先頭付近へ集める準備',
      arr: a.slice(),
    });
    const collected = collectKeys(a, steps);
    steps.push({
      kind: 'keys_done',
      count: collected.keys.length,
      arr: a.slice(),
    });

    for (let start = 0; start < n; start += RUN_SIZE) {
      const end = Math.min(start + RUN_SIZE - 1, n - 1);
      steps.push({ kind: 'run_start', lo: start, hi: end, arr: a.slice() });
      insertionSortRange(a, start, end, steps);
      steps.push({ kind: 'run_done', lo: start, hi: end, arr: a.slice() });
    }

    for (let width = RUN_SIZE; width < n; width *= 2) {
      steps.push({ kind: 'level_start', width: width, arr: a.slice() });
      for (let lo = 0; lo + width < n; lo += width * 2) {
        const mid = lo + width - 1;
        const hi = Math.min(lo + width * 2 - 1, n - 1);
        if (mid + 1 <= hi) {
          mergeRange(a, lo, mid, hi, steps);
        }
      }
      steps.push({ kind: 'level_done', width: width, arr: a.slice() });
    }

    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-grail',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'グレイルソートのデモ（キー候補は紫、ラン整列・併合はウィキソートと同型の可視化）',
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
      if (s.kind === 'key_found') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.pos, 'pivot']]);
        api.setCaption(
          'キー候補 ' +
            s.keyCount +
            '/' +
            KEY_TARGET +
            ': 位置 ' +
            s.pos +
            ' の値 ' +
            s.value
        );
        return;
      }
      if (s.kind === 'keys_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          'キー収集フェーズ完了（' + s.count + ' 個の一意な値を検出）'
        );
        return;
      }
      if (s.kind === 'run_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'range'));
        api.setCaption(
          '小さなラン整列: 長さ ' + (s.hi - s.lo + 1) + ' [' + s.lo + '…' + s.hi + ']'
        );
        return;
      }
      if (s.kind === 'run_compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.lo, 'compare'], [s.hi, 'compare']]);
        api.setCaption('ラン内比較: 位置 ' + s.lo + ' と ' + s.hi);
        return;
      }
      if (s.kind === 'run_shift' || s.kind === 'run_write') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.pos, 'write']]);
        api.setCaption('ラン内で値を確定: 位置 ' + s.pos);
        return;
      }
      if (s.kind === 'run_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ラン [' + s.lo + '…' + s.hi + '] の整列が完了');
        return;
      }
      if (s.kind === 'level_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          'ボトムアップ併合: ラン幅 ' + s.width + ' → ' + (s.width * 2)
        );
        return;
      }
      if (s.kind === 'merge_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'range'));
        api.setCaption(
          '併合: 左 [' + s.lo + '…' + s.mid + '] と 右 [' + (s.mid + 1) + '…' + s.hi + ']'
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
        api.setCaption('区間 ' + s.lo + ' … ' + s.hi + ' の併合が完了');
        return;
      }
      if (s.kind === 'level_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ラン幅 ' + s.width * 2 + ' までの併合レベルが完了');
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
  id="grail-sort-demo"
  data_prefix="grail"
  script=sort_demo_js
%}

配列が大きくなり内部バッファを超えるレベルでは、本番のグレイルソートはブロック分割・回転・キータグ付けによるインプレース併合へ切り替わる。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000012 |        0.000568 |            1758 |            1764 |
|        512 |        0.000021 |        0.000508 |            1761 |            1768 |
|       1024 |        0.000041 |        0.000632 |            1770 |            1776 |
|       2048 |        0.000082 |        0.000682 |            1786 |            1792 |
|       4096 |        0.000170 |        0.000744 |            1818 |            1824 |
|       8192 |        0.000346 |        0.000820 |            1858 |            1864 |
|      16384 |        0.000741 |        0.001085 |            1990 |            1996 |
|      32768 |        0.001566 |        0.007512 |            2274 |            2280 |
|      65536 |        0.003301 |        0.004932 |            2785 |            2792 |
|     131072 |        0.007035 |        0.014111 |            3810 |            3816 |
|     262144 |        0.015137 |        0.078975 |            5857 |            5864 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="grail" %}
