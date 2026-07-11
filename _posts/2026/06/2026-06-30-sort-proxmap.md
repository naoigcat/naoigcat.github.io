---
title:     プロックスマップソートで配列を並び替える
date:      2026-06-30 22:32:30 +0900
tags:      sort
sort_demo: true
---

## プロックスマップソートを使用する

プロックスマップソートは、キーを近接写像 (proximity map) で決めた部分配列へ仕分け、各部分配列内を挿入しながら整列する。

バケットソートや基数ソートと同系統だが、バケットソートが「仕分け → バケット内ソート → 連結」の二段階であるのに対し、プロックスマップソートは要素を置くたびに部分配列内で挿入ソートを行う点が異なる。

1.  **ヒット数 `H`**: 各キーに `mapKey` 関数を適用し、同じ部分配列へ入る要素数を数える。
2.  **近接写像 `P`**: ヒット数の累積和から、各部分配列が出力配列 `A2` のどこから始まるかを求める。部分配列のサイズはちょうどそのヒット数分確保される。
3.  **位置 `L`**: 元配列 `A` の各要素について、`L[i] = P[mapKey(A[i])]` として配置開始位置を記録する。
4.  **配置**: `A` を左から走査し、各要素を `A2` の対応部分配列へ置く。衝突したら部分配列内で挿入ソートし、より大きいキーを右へ 1 セルずつずらして空きを作る。部分配列はヒット数分だけ確保されているため、隣の部分配列へはみ出さない。

```pseudocode
procedure proxmap_sort(A)
  n = length(A)
  for each bucket b: H[b] = 0
  for each x in A:
    b = mapKey(x)
    H[b] = H[b] + 1
  running = 0
  for each bucket b:
    if H[b] > 0 then
      P[b] = running
      running = running + H[b]
  for i from 0 to n - 1:
    L[i] = P[mapKey(A[i])]
  A2 = array of n empty slots
  for i from 0 to n - 1:
    start = L[i]
    insert A[i] into A2 at start, shifting larger keys right within the subarray
  A = A2
```

整数キー `1..n` を `n` 個の部分配列へ写す典型例では `mapKey(x) = floor((x - min) / (max - min) * (n - 1))` のように値域を等分する。

分布が一様なら `O(n)` に近づくが、同一部分配列に偏ると `O(n²)` になる。

整列後は `P` と `mapKey` を保持しておけば、ProxmapSearch により平均 `O(1)` でキー検索できる。静的な大規模データセットで検索頻度が高い場合に有利だが、更新のたびに近接写像を組み直す必要がある。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('proxmap-sort-demo', function (root) {
  const SUBARRAY_COUNT = 5;

  function mapKey(value, minVal, maxVal, subCount) {
    if (maxVal === minVal) {
      return 0;
    }
    const idx = Math.floor(
      ((value - minVal) / (maxVal - minVal)) * (subCount - 1)
    );
    return Math.min(idx, subCount - 1);
  }

  function formatHitList(hitList) {
    const parts = [];
    let b;
    for (b = 0; b < hitList.length; b++) {
      if (hitList[b] > 0) {
        parts.push('部分配列 ' + b + ' → ' + hitList[b] + ' 個');
      }
    }
    return parts.length ? parts.join('、') : '（まだなし）';
  }

  function formatProxMap(proxMap) {
    const parts = [];
    let b;
    for (b = 0; b < proxMap.length; b++) {
      if (proxMap[b] >= 0) {
        parts.push('P[' + b + '] = ' + proxMap[b]);
      }
    }
    return parts.length ? parts.join('、') : '（まだなし）';
  }

  function mountOutputBars(container, values) {
    container.innerHTML = '';
    if (!values.length) {
      container.removeAttribute('role');
      container.removeAttribute('aria-label');
      return;
    }
    const defined = values.filter(function (v) {
      return v != null;
    });
    const min =
      defined.length ? Math.min.apply(null, defined) : 0;
    const max =
      defined.length ? Math.max.apply(null, defined) : 0;
    const span = Math.max(max - min, 1);
    container.setAttribute('role', 'list');
    container.setAttribute(
      'aria-label',
      'ProxmapSort の出力配列 A2。左から位置 0、1…の順です。'
    );
    let i;
    for (i = 0; i < values.length; i++) {
      const v = values[i];
      const bar = document.createElement('div');
      bar.className = 'sort-demo__bar';
      bar.setAttribute('role', 'listitem');
      if (v == null) {
        bar.classList.add('sort-demo__bar--gap');
        bar.style.height = '8px';
        bar.style.opacity = '0.35';
        bar.removeAttribute('title');
        bar.setAttribute(
          'aria-label',
          DemoSort.barAccessibilityLabel(i, '空', 'gap')
        );
      } else {
        bar.style.height = 28 + ((v - min) / span) * 92 + 'px';
        bar.style.opacity = '';
        bar.setAttribute('title', String(v));
        bar.setAttribute(
          'aria-label',
          DemoSort.barAccessibilityLabel(i, String(v), null)
        );
      }
      container.appendChild(bar);
    }
  }

  function generateSteps(initial) {
    const a = initial.slice();
    const n = a.length;
    const steps = [];
    if (n === 0) {
      steps.push({ kind: 'done', arr: [] });
      return steps;
    }

    const minVal = Math.min.apply(null, a);
    const maxVal = Math.max.apply(null, a);
    const hitList = new Array(SUBARRAY_COUNT);
    const mapKeys = new Array(n);
    let i;
    let b;

    for (b = 0; b < SUBARRAY_COUNT; b++) {
      hitList[b] = 0;
    }

    steps.push({
      kind: 'phase',
      phase: 'hit',
      arr: a.slice(),
      minVal: minVal,
      maxVal: maxVal,
    });

    for (i = 0; i < n; i++) {
      const mk = mapKey(a[i], minVal, maxVal, SUBARRAY_COUNT);
      mapKeys[i] = mk;
      steps.push({
        kind: 'hit_scan',
        idx: i,
        value: a[i],
        mapKey: mk,
        arr: a.slice(),
        hitList: hitList.slice(),
      });
      hitList[mk]++;
      steps.push({
        kind: 'hit_bump',
        idx: i,
        value: a[i],
        mapKey: mk,
        arr: a.slice(),
        hitList: hitList.slice(),
      });
    }

    const proxMap = new Array(SUBARRAY_COUNT);
    let running = 0;
    for (b = 0; b < SUBARRAY_COUNT; b++) {
      proxMap[b] = hitList[b] > 0 ? running : -1;
      if (hitList[b] > 0) {
        running += hitList[b];
      }
    }

    steps.push({
      kind: 'prox_done',
      arr: a.slice(),
      hitList: hitList.slice(),
      proxMap: proxMap.slice(),
    });

    const location = new Array(n);
    for (i = 0; i < n; i++) {
      location[i] = proxMap[mapKeys[i]];
    }

    const a2 = new Array(n);
    for (i = 0; i < n; i++) {
      a2[i] = null;
    }

    steps.push({
      kind: 'phase',
      phase: 'place',
      arr: a.slice(),
      output: a2.slice(),
    });

    for (i = 0; i < n; i++) {
      const key = a[i];
      const start = location[i];
      let insertIdx = start;

      steps.push({
        kind: 'place_start',
        idx: i,
        value: key,
        start: start,
        mapKey: mapKeys[i],
        arr: a.slice(),
        output: a2.slice(),
      });

      let placed = false;
      while (!placed) {
        if (a2[insertIdx] == null) {
          a2[insertIdx] = key;
          placed = true;
          steps.push({
            kind: 'place_done',
            idx: i,
            pos: insertIdx,
            value: key,
            arr: a.slice(),
            output: a2.slice(),
          });
        } else if (key < a2[insertIdx]) {
          steps.push({
            kind: 'shift_compare',
            idx: i,
            pos: insertIdx,
            value: key,
            existing: a2[insertIdx],
            arr: a.slice(),
            output: a2.slice(),
          });
          let end = insertIdx + 1;
          while (end < n && a2[end] != null) {
            end++;
          }
          let k;
          for (k = end - 1; k >= insertIdx; k--) {
            a2[k + 1] = a2[k];
          }
          a2[insertIdx] = key;
          placed = true;
          steps.push({
            kind: 'place_shift',
            idx: i,
            pos: insertIdx,
            value: key,
            arr: a.slice(),
            output: a2.slice(),
          });
        } else {
          insertIdx++;
        }
      }
    }

    steps.push({ kind: 'done', arr: a2.slice() });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-proxmap',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'ProxmapSort のデモ（ヒット数集計は水色、配置は確定の書き込み／挿入シフトは緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    afterRebuild: function (api) {
      mountOutputBars(
        api.barsEl,
        api.steps[0] ? api.steps[0].arr : []
      );
    },
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'phase') {
        if (s.phase === 'place') {
          mountOutputBars(barsEl, s.output);
        } else {
          api.mountBars(barsEl, s.arr);
        }
        DemoSort.clearRoles(barsEl);
        if (s.phase === 'hit') {
          api.setCaption(
            'フェーズ1: mapKey でヒット数 H を集計（値域 [' +
              s.minVal +
              ', ' +
              s.maxVal +
              '] → ' +
              SUBARRAY_COUNT +
              ' 部分配列）'
          );
        } else {
          api.setCaption(
            'フェーズ2: 各要素を A2 の部分配列へ挿入しながら整列します'
          );
        }
        return;
      }
      if (s.kind === 'hit_scan') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.idx, 'cursor']]);
        api.setCaption(
          '走査: 位置 ' +
            s.idx +
            ' の値 ' +
            s.value +
            ' → mapKey = ' +
            s.mapKey
        );
        return;
      }
      if (s.kind === 'hit_bump') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          'ヒット数を更新（' + formatHitList(s.hitList) + '）'
        );
        return;
      }
      if (s.kind === 'prox_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          '近接写像 P を確定（' + formatProxMap(s.proxMap) + '）'
        );
        return;
      }
      if (s.kind === 'place_start') {
        mountOutputBars(barsEl, s.output);
        DemoSort.assignRoles(barsEl, [[s.start, 'range']]);
        api.setCaption(
          '配置: 位置 ' +
            s.idx +
            ' の値 ' +
            s.value +
            ' を部分配列 ' +
            s.mapKey +
            '（A2[' +
            s.start +
            '] から）へ'
        );
        return;
      }
      if (s.kind === 'shift_compare') {
        mountOutputBars(barsEl, s.output);
        DemoSort.assignRoles(barsEl, [[s.pos, 'compare']]);
        api.setCaption(
          '挿入: 値 ' +
            s.value +
            ' < ' +
            s.existing +
            ' のため右へシフトして空きを作ります'
        );
        return;
      }
      if (s.kind === 'place_shift') {
        mountOutputBars(barsEl, s.output);
        DemoSort.assignRoles(barsEl, [[s.pos, 'write']]);
        api.setCaption(
          '配置完了: 値 ' + s.value + ' を位置 ' + s.pos + ' に書き込み（シフト後）'
        );
        return;
      }
      if (s.kind === 'place_done') {
        mountOutputBars(barsEl, s.output);
        DemoSort.assignRoles(barsEl, [[s.pos, 'write']]);
        api.setCaption(
          '配置完了: 値 ' + s.value + ' を位置 ' + s.pos + ' に書き込み'
        );
        return;
      }
      if (s.kind === 'done') {
        mountOutputBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption('ソート完了');
      }
    },
    stepPauseMs: 280,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="proxmap-sort-demo"
  data_prefix="proxmap"
  script=sort_demo_js
%}

## バケットソートとの違い

[バケットソート](/2026/06/23/sort-bucket.html) も値域を区間に分割して仕分けるが、ProxmapSort では仕分けと整列が同時進行する。バケットソートがすべての要素をバケットへ入れてから各バケットをまとめてソートするのに対し、プロックスマップソートは要素を 1 つ置くたびに部分配列内で挿入位置を決める。

| 観点 | プロックスマップソート | バケットソート |
| --- | --- | --- |
| 整列のタイミング | 配置と同時（オンライン的） | 仕分け完了後にバケットごと |
| 部分配列のサイズ | ヒット数から **ちょうど** 確保 | 等幅区間（要素数は可変） |
| 追加構造 | `H`, `P`, `L`, `A2` | バケット配列 |
| 検索 | ProxmapSearch で平均 `O(1)` | 整列結果のみ（別途索引が必要） |

`mapKey` の設計が性能を左右する点はバケットソートと同様である。分布が偏ると 1 部分配列に要素が集中し、最悪計算量 `O(n²)` に近づく。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000002 |        0.000048 |            1694 |            1700 |
|        512 |        0.000005 |        0.000031 |            1709 |            1716 |
|       1024 |        0.000009 |        0.000059 |            1746 |            1752 |
|       2048 |        0.000023 |        0.000070 |            1818 |            1824 |
|       4096 |        0.000042 |        0.000096 |            1878 |            1892 |
|       8192 |        0.000098 |        0.000290 |            2116 |            2148 |
|      16384 |        0.000199 |        0.000301 |            2754 |            2788 |
|      32768 |        0.000380 |        0.000545 |            3908 |            3940 |
|      65536 |        0.000785 |        0.007048 |            6212 |            6244 |
|     131072 |        0.001574 |        0.009554 |           10819 |           10852 |
|     262144 |        0.002844 |        0.022800 |           19982 |           20076 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="proxmap" %}
