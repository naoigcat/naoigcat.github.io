---
title:     多方向マージソートで配列を並び替える
date:      2026-09-12 06:50:04 +0900
tags:      sort
mathjax:   true
sort_demo: true
---

## 多方向マージソートを使用する

多方向マージソート (`multiway merge sort` / `k-way merge sort`) は、通常の[マージソート](/2026/05/03/sort-merge.html)が 2 本の整列済み列をマージするのに対し、一度に `k` 本（本稿では `k = 4`）をまとめてマージする分割統治法である。

外部整列ではテープやファイル本数に応じて `k` を選び、初期ランを k 本ずつまとめていく用途でも同じ部品が使われる。内部メモリ向けでも、マージ段数はおよそ $$\log_k n$$ に落ち、各段のコストは線形なので全体は $$\Theta(n \log n)$$ を保つ。

1.  **分割**: 区間を最大 `k` 個の連続部分にほぼ等分する。要素が 1 つ以下ならそのままソート済みとみなす。
2.  **再帰**: 各部分に対して同じ手順を繰り返す。
3.  **k 方向マージ**: 各部分は昇順になっている前提で、各ランの「先頭」を比較し、最小（同値ならより左のラン）を出力へ確定する。選んだランの先頭を 1 つ進め、全ランが尽きるまで繰り返す。
4.  **書き戻し**: マージ結果を元の区間へ写す。

本稿のデモとベンチマークは、先頭比較を長さ `k` の線形走査で行う単純実装である。`k` が大きい外部マージでは、同じ選択を[敗者木](/2026/08/26/sort-loser-tree.html)やヒープで $$O(\log k)$$ に落とすことが多い。

```pseudocode
procedure merge_k_way(runs[0..k))
  heads[i] = 0 for each run i
  while some run still has unread elements
    pick run i with smallest heads[i] value
      (ties: smallest i, for stability)
    append runs[i][heads[i]] to output
    heads[i] = heads[i] + 1
  return output

procedure multiway_merge_sort(A)
  n = length(A)
  if n <= 1 then
    return
  split A into up to k contiguous parts of nearly equal length
  for each part P
    multiway_merge_sort(P)
  merged = merge_k_way(the k sorted parts)
  copy merged back into A
```

分割の深さが $$O(\log_k n)$$、各層のマージが $$O(k n)$$（固定 `k` なら $$O(n)$$）なので最悪計算量は $$O(n \log n)$$ である。作業用バッファに $$O(n)$$ の追加領域が要る。同値を左ラン優先で取れば安定ソートになる。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('multiway-merge-sort-demo', function (root) {
  const WAY = 4;

  function buildDisplay(a, lo, tmp) {
    const d = a.slice();
    for (let t = 0; t < tmp.length; t++) {
      d[lo + t] = tmp[t];
    }
    return d;
  }

  function rangePairs(lo, hiExclusive, role) {
    const pairs = [];
    for (let k = lo; k < hiExclusive; k++) {
      pairs.push([k, role]);
    }
    return pairs;
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];

    function mergeKWay(lo, bounds) {
      const runs = bounds.map(function (b) {
        return a.slice(b.lo, b.hi);
      });
      const heads = runs.map(function () {
        return 0;
      });
      const tmp = [];
      const absHeads = bounds.map(function (b) {
        return b.lo;
      });

      steps.push({
        kind: 'merge_start',
        lo: lo,
        hi: bounds[bounds.length - 1].hi,
        bounds: bounds.map(function (b) {
          return { lo: b.lo, hi: b.hi - 1 };
        }),
        arr: a.slice(),
      });

      for (;;) {
        let best = -1;
        let bestVal = 0;
        for (let i = 0; i < runs.length; i++) {
          if (heads[i] < runs[i].length) {
            const v = runs[i][heads[i]];
            if (best < 0 || v < bestVal || (v === bestVal && i < best)) {
              best = i;
              bestVal = v;
            }
          }
        }
        if (best < 0) {
          break;
        }

        const compareHeads = [];
        for (let i = 0; i < runs.length; i++) {
          if (heads[i] < runs[i].length) {
            compareHeads.push(absHeads[i] + heads[i]);
          }
        }
        steps.push({
          kind: 'merge_compare',
          lo: lo,
          hi: bounds[bounds.length - 1].hi,
          heads: compareHeads.slice(),
          pick: absHeads[best] + heads[best],
          arr: buildDisplay(a, lo, tmp),
        });

        tmp.push(bestVal);
        heads[best] += 1;
        steps.push({
          kind: 'merge_write',
          lo: lo,
          hi: bounds[bounds.length - 1].hi,
          writePos: lo + tmp.length - 1,
          arr: buildDisplay(a, lo, tmp),
        });
      }

      for (let t = 0; t < tmp.length; t++) {
        a[lo + t] = tmp[t];
      }
      steps.push({
        kind: 'merge_done',
        lo: lo,
        hi: bounds[bounds.length - 1].hi - 1,
        arr: a.slice(),
      });
    }

    function multiwayMergeSort(lo, hi) {
      const n = hi - lo;
      if (n <= 1) {
        return;
      }

      const bounds = [];
      const base = Math.floor(n / WAY);
      const rem = n % WAY;
      let start = lo;
      for (let i = 0; i < WAY; i++) {
        const len = base + (i < rem ? 1 : 0);
        if (len === 0) {
          continue;
        }
        const end = start + len;
        bounds.push({ lo: start, hi: end });
        start = end;
      }

      steps.push({
        kind: 'split',
        lo: lo,
        hi: hi - 1,
        bounds: bounds.map(function (b) {
          return { lo: b.lo, hi: b.hi - 1 };
        }),
        arr: a.slice(),
      });

      for (let i = 0; i < bounds.length; i++) {
        multiwayMergeSort(bounds[i].lo, bounds[i].hi);
      }

      if (bounds.length <= 1) {
        return;
      }
      mergeKWay(lo, bounds);
    }

    multiwayMergeSort(0, a.length);
    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-multiway-merge',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      '多方向マージソートのデモ（k=4。分割は青、先頭比較はオレンジ、確定書き込みは緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'split') {
        api.mountBars(barsEl, s.arr);
        const roles = rangePairs(s.lo, s.hi + 1, 'range');
        DemoSort.assignRoles(barsEl, roles);
        const parts = s.bounds
          .map(function (b) {
            return '[' + b.lo + '..' + b.hi + ']';
          })
          .join(', ');
        api.setCaption('分割 (k=' + WAY + '): ' + parts);
        return;
      }
      if (s.kind === 'merge_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'range'));
        api.setCaption(
          'k 方向マージ開始: 位置 ' + s.lo + ' … ' + (s.hi - 1)
        );
        return;
      }
      if (s.kind === 'merge_compare') {
        api.mountBars(barsEl, s.arr);
        const roles = s.heads.map(function (h) {
          return [h, 'compare'];
        });
        roles.push([s.pick, 'cursor']);
        DemoSort.assignRoles(barsEl, roles);
        api.setCaption(
          '各ラン先頭を比較し、位置 ' + s.pick + ' を選択'
        );
        return;
      }
      if (s.kind === 'merge_write') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.writePos, 'write']]);
        api.setCaption('位置 ' + s.writePos + ' へ確定書き込み');
        return;
      }
      if (s.kind === 'merge_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi + 1, 'range'));
        api.setCaption('区間 [' + s.lo + '..' + s.hi + '] のマージ完了');
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
  id="multiway-merge-sort-demo"
  data_prefix="multiway-merge"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[マージソート](/2026/05/03/sort-merge.html)は常に 2 方向マージであり、本稿はその `k` 一般化である。

[ポリフェーズマージソート](/2026/06/26/sort-polyphase-merge.html)や[カスケードマージソート](/2026/06/25/sort-cascade-merge.html)は、テープ本数が限られた外部整列向けにラン分布やパス構成を工夫する系統である。

[クアッドソート](/2026/08/17/sort-quad.html)は 4 本をボトムアップでマージする実装の一例だが、適応的な枝刈りや交換ネットワークなど、本稿の素直な再帰 k 方向マージとは別の工夫を含む。

[敗者木ソート](/2026/08/26/sort-loser-tree.html)は要素全体をトーナメントにする整列本体であり、多方向マージの「`k` 本の先頭から最小を取る」部品としても使われる。

## 時間計算量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000018 |        0.000247 |               4 |               4 |
|        512 |        0.000047 |        0.000263 |               8 |               8 |
|       1024 |        0.000077 |        0.000176 |              16 |              16 |
|       2048 |        0.000194 |        0.000713 |              32 |              32 |
|       4096 |        0.000335 |        0.000847 |              64 |              64 |
|       8192 |        0.000855 |        0.001521 |             128 |             128 |
|      16384 |        0.001479 |        0.002574 |             256 |             256 |
|      32768 |        0.004319 |        0.010915 |             512 |             512 |
|      65536 |        0.009095 |        0.023376 |            1024 |            1024 |
|     131072 |        0.019601 |        0.083974 |            2048 |            2048 |
|     262144 |        0.034262 |        0.070343 |            4096 |            4096 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="multiway_merge" %}
