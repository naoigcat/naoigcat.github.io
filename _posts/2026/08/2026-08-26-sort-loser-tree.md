---
title:     敗者木ソートで配列を並び替える
date:      2026-08-26 01:25:09 +0900
tags:      sort
sort_demo: true
---

## 敗者木ソートを使用する

敗者木ソート (`loser tree sort`) は、各要素を葉とする完全二分木でトーナメントを行い、最小を繰り返し取り出す整列である。内部ノードに勝者ではなく敗者（昇順なら大きい方のインデックス）を残し、全体の勝者だけを根の外（`ls[0]`）に置く点が[トーナメントソート](/2026/05/26/sort-tournament.html)（勝者木）と異なる。

更新時は「新しい挑戦者」と各内部ノードに記録された敗者だけを比較すればよく、左右の子を両方読み直さずにパス上の再試合で新しい全体勝者を決められる。k 本の整列済み列を併合する外部マージでも、同じ形の敗者木が比較更新を `O(log k)` に抑える部品として使われる。

1.  **木の準備**: 要素数 `n` 以上の 2 の冪 `k` を葉数とし、配列 `ls`（長さ `k`）を用意する。`ls[0]` は全体の勝者インデックス、`ls[1..k)` は各内部ノードの敗者インデックスを持つ。葉 `i`（`i ≥ n` は無効）は値配列上の位置そのものとみなす。
2.  **構築**: 葉から根へ向かい、左右の子の勝者同士を比較して敗者を `ls[i]` に書き、勝者を親へ渡す。最終的な勝者を `ls[0]` に置く。
3.  **抽出**: `ls[0]` が示す位置の値を出力へ書き、その葉を番兵（比較上の無限大）で無効化する。
4.  **更新**: 無効化した葉から親へ遡る。各内部ノードでは挑戦者 `s` と記録済み敗者 `ls[t]` を比べ、大きい方を新しい敗者として残し、小さい方を `s` として上へ進める。根に達したら `ls[0]` を更新する。
5.  **繰り返し**: `n` 回手順 3〜4 を行えば昇順に整列する。

```pseudocode
procedure adjust(A, ls, k, s)
  t = parent of leaf s   // (s + k) / 2
  while t > 0
    if key(A, s) > key(A, ls[t])
      swap s and ls[t]   // loser stays in ls[t], winner continues as s
    t = t / 2
  ls[0] = s

procedure loser_tree_sort(A)
  n = length(A)
  k = smallest power of 2 with k >= n
  build ls[1..k) with losers bottom-up; ls[0] = overall winner
  for pos from 0 to n - 1
    idx = ls[0]
    output[pos] = A[idx]
    mark A[idx] as removed (sentinel)
    adjust(A, ls, k, idx)
  copy output back into A
```

比較回数は構築・抽出合わせて `O(n log n)`、敗者木と出力バッファに `O(n)` の追加領域が要る。等値の扱いは規約依存で、一般に不安定である。勝者木と同じ漸近計算量だが、パス上の再試合が「記録済み敗者との 1 比較」に落ちるため、k 分マージの実装では敗者木が選ばれやすい。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('loser-tree-sort-demo', function (root) {
  function generateSteps(initial) {
    const work = initial.slice();
    const display = initial.slice();
    const steps = [];
    const n = work.length;
    if (n <= 1) {
      steps.push({ kind: 'done', arr: display.slice() });
      return steps;
    }

    let cap = 1;
    while (cap < n) {
      cap *= 2;
    }
    const ls = new Array(cap).fill(-1);
    const winner = new Array(2 * cap).fill(-1);

    function keyOf(idx) {
      if (idx < 0) {
        return Infinity;
      }
      return work[idx];
    }

    function loserAndWinner(left, right) {
      if (left < 0) {
        return { loser: -1, win: right };
      }
      if (right < 0) {
        return { loser: -1, win: left };
      }
      if (keyOf(left) <= keyOf(right)) {
        return { loser: right, win: left };
      }
      return { loser: left, win: right };
    }

    for (let i = 0; i < cap; i++) {
      winner[cap + i] = i < n ? i : -1;
    }

    steps.push({
      kind: 'caption',
      text: '敗者木を構築: 各内部ノードに敗者インデックスを残し、勝者だけを親へ渡す',
      arr: display.slice(),
      sortedUpTo: 0,
    });

    for (let i = cap - 1; i >= 1; i--) {
      const lo = winner[2 * i];
      const hi = winner[2 * i + 1];
      if (lo >= 0 && hi >= 0) {
        steps.push({
          kind: 'compare',
          lo: lo,
          hi: hi,
          arr: display.slice(),
          phase: 'build',
          sortedUpTo: 0,
        });
      }
      const pair = loserAndWinner(lo, hi);
      ls[i] = pair.loser;
      winner[i] = pair.win;
    }
    ls[0] = winner[1];

    for (let pos = 0; pos < n; pos++) {
      const win = ls[0];
      steps.push({
        kind: 'champion',
        win: win,
        pos: pos,
        arr: display.slice(),
        sortedUpTo: pos,
      });
      display[pos] = work[win];
      work[win] = Infinity;
      steps.push({
        kind: 'write',
        pos: pos,
        win: win,
        arr: display.slice(),
        sortedUpTo: pos,
      });

      let s = win;
      let t = Math.floor((s + cap) / 2);
      while (t > 0) {
        const recorded = ls[t];
        if (recorded >= 0 || s >= 0) {
          const a = s;
          const b = recorded;
          if (a >= 0 && b >= 0) {
            steps.push({
              kind: 'compare',
              lo: a,
              hi: b,
              arr: display.slice(),
              phase: 'rebuild',
              sortedUpTo: pos,
            });
          }
          if (keyOf(s) > keyOf(recorded)) {
            ls[t] = s;
            s = recorded;
          }
        }
        t = Math.floor(t / 2);
      }
      ls[0] = s;
    }

    steps.push({ kind: 'done', arr: display.slice() });
    return steps;
  }

  function paintBarStates(container, sortedUpTo, pairs) {
    const all = [];
    for (let k = 0; k < sortedUpTo; k++) {
      all.push([k, 'sorted']);
    }
    for (const pair of pairs) {
      all.push(pair);
    }
    DemoSort.assignRoles(container, all);
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-loser-tree',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      '敗者木ソートのデモ（確定済みは紫、比較はオレンジ、勝者はカーソル、書き込みは書き込み色）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'caption') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.sortedUpTo, []);
        api.setCaption(s.text);
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.sortedUpTo, [
          [s.lo, 'compare'],
          [s.hi, 'compare'],
        ]);
        api.setCaption(
          (s.phase === 'build' ? '構築: ' : '更新: ') +
            '位置 ' +
            s.lo +
            ' と ' +
            s.hi +
            ' を比較（大きい方が敗者として木に残る）'
        );
        return;
      }
      if (s.kind === 'champion') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.sortedUpTo, [[s.win, 'cursor']]);
        api.setCaption(
          'ls[0]: 位置 ' + s.win + ' が次の最小（出力位置 ' + s.pos + '）'
        );
        return;
      }
      if (s.kind === 'write') {
        api.mountBars(barsEl, s.arr);
        paintBarStates(barsEl, s.sortedUpTo, [[s.pos, 'write']]);
        api.setCaption(
          '位置 ' + s.pos + ' に最小値を確定（元は位置 ' + s.win + '）'
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

{% include sort-demo.html
  id="loser-tree-sort-demo"
  data_prefix="loser-tree"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[トーナメントソート](/2026/05/26/sort-tournament.html)は内部ノードに勝者を置く勝者木であり、更新時に左右の子の勝者を読み直す。

[選択ソート](/2026/05/11/sort-selection.html)と同じく最小を繰り返し確定するが、木で比較結果を再利用する。

[ファンネルソート](/2026/08/08/sort-funnel.html)の k 入力マージャも多入力併合だが、本稿の敗者木は固定長のトーナメント構造そのものを整列の本体にする。

## 計算時間量および空間計算量を計測する

<!-- sort-benchmark-result:start -->

|       Size |    Average time |    Maximum time |  Average memory |  Maximum memory |
|-----------:|----------------:|----------------:|----------------:|----------------:|
|        256 |        0.000009 |        0.000069 |               8 |               8 |
|        512 |        0.000020 |        0.000134 |              16 |              16 |
|       1024 |        0.000043 |        0.000140 |              32 |              32 |
|       2048 |        0.000092 |        0.000169 |              64 |              64 |
|       4096 |        0.000201 |        0.000468 |             128 |             128 |
|       8192 |        0.000434 |        0.000752 |             256 |             256 |
|      16384 |        0.000946 |        0.002635 |             512 |             512 |
|      32768 |        0.002032 |        0.008853 |            1024 |            1024 |
|      65536 |        0.004436 |        0.008370 |            2048 |            2048 |
|     131072 |        0.009761 |        0.026974 |            4096 |            4096 |
|     262144 |        0.023467 |        0.126202 |            8192 |            8192 |

<!-- sort-benchmark-result:end -->

{% include sort-benchmark.md algorithm="loser_tree" %}
