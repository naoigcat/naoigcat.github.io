---
title:     スターリンソートで配列を並び替える
date:      2026-09-10 04:32:31 +0900
tags:      sort
sort_demo: true
---

## スターリンソートを使用する

スターリンソート (`stalin sort`, `drop sort`) は、左から右へ走査しながら「直前に残した値より小さい要素」を配列から取り除き、残った列だけを結果とするジョークアルゴリズムである。要素を並べ替えるのではなく、順序に合わないものを捨てるため、出力の長さは入力より短くなりうる。

名前は、粛清で「都合の悪いもの」を消すという暗い比喩に由来するネット上の造語とされる。整列の定義（入力の並べ替え）を満たさないため、実用アルゴリズムではなく、計算量の話の導入やジョーク枠として扱われる。

1.  **先頭の採用**: 配列 `A` が空でなければ、先頭要素を必ず残す。これを現時点の「最後に残した値」`last` とする。
2.  **走査**: 残りの各要素 `x` について、`x >= last` なら残し、`last` を `x` に更新する。そうでなければ `x` を捨てる（配列から削除する）。
3.  **結果**: 残った列は非減少列になる。元の要素の相対順のうち、捨てられなかったものだけが保たれる。

```pseudocode
procedure stalin_sort(A)
  if A is empty then
    return A
  result = [A[0]]
  last = A[0]
  for i from 1 to length(A) - 1
    if A[i] >= last then
      append A[i] to result
      last = A[i]
  return result
```

1 回の線形走査で終わるため時間は `O(n)`、結果用の補助配列を使うなら空間は `O(n)` である（インプレースに詰めても時間は同様）。同値は `>=` で残すため、捨てられなかった要素どうしの相対順は入力どおりで、その意味では「安定」だが、捨てられた要素は結果に現れない。

昇順の並べ替えとしては正しくない。すでに非減少なら全要素が残り、降順なら先頭以外がほぼ捨てられる。入力の並べ替えではなく部分集合の抽出なので、ベンチマークで他のソートと並べても意味が薄い。

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('stalin-sort-demo', function (root) {
  function generateSteps(initial) {
    const a = initial.slice();
    const steps = [];
    if (a.length === 0) {
      steps.push({ kind: 'done', arr: [] });
      return steps;
    }

    const kept = [a[0]];
    let last = a[0];
    steps.push({ kind: 'keep_first', arr: a.slice(), keptLen: 1 });

    for (let i = 1; i < a.length; i++) {
      const value = a[i];
      steps.push({
        kind: 'compare',
        idx: i,
        value: value,
        last: last,
        arr: a.slice(),
        keptLen: kept.length,
      });
      if (value >= last) {
        kept.push(value);
        last = value;
        steps.push({
          kind: 'keep',
          idx: i,
          value: value,
          arr: a.slice(),
          keptLen: kept.length,
        });
      } else {
        steps.push({
          kind: 'purge',
          idx: i,
          value: value,
          last: last,
          arr: a.slice(),
          keptLen: kept.length,
        });
        a.splice(i, 1);
        steps.push({
          kind: 'removed',
          value: value,
          arr: a.slice(),
          keptLen: kept.length,
        });
        i -= 1;
      }
    }

    steps.push({ kind: 'done', arr: a.slice() });
    return steps;
  }

  function paintKept(container, keptLen, pairs) {
    const all = [];
    for (let k = 0; k < keptLen; k++) {
      all.push([k, 'sorted']);
    }
    for (const pair of pairs) {
      all.push(pair);
    }
    DemoSort.assignRoles(container, all);
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-stalin',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 4],
    initialCaption:
      'スターリンソートのデモ（残した要素は紫、比較はオレンジ、粛清対象は緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'keep_first') {
        api.mountBars(barsEl, s.arr);
        paintKept(barsEl, s.keptLen, []);
        api.setCaption('先頭の値 ' + s.arr[0] + ' は必ず残す');
        return;
      }
      if (s.kind === 'compare') {
        api.mountBars(barsEl, s.arr);
        paintKept(barsEl, s.keptLen, [
          [s.keptLen - 1, 'compare'],
          [s.idx, 'compare'],
        ]);
        api.setCaption(
          '比較: 最後に残した値 ' + s.last + ' と 位置 ' + s.idx + ' の値 ' + s.value
        );
        return;
      }
      if (s.kind === 'keep') {
        api.mountBars(barsEl, s.arr);
        paintKept(barsEl, s.keptLen, []);
        api.setCaption(
          '値 ' + s.value + ' は非減少なので残す（残存 ' + s.keptLen + ' 個）'
        );
        return;
      }
      if (s.kind === 'purge') {
        api.mountBars(barsEl, s.arr);
        paintKept(barsEl, s.keptLen, [[s.idx, 'swap']]);
        api.setCaption(
          '値 ' + s.value + ' は ' + s.last + ' より小さいので粛清する'
        );
        return;
      }
      if (s.kind === 'removed') {
        api.mountBars(barsEl, s.arr);
        paintKept(barsEl, s.keptLen, []);
        api.setCaption(
          '値 ' + s.value + ' を削除した（残存 ' + s.keptLen + ' 個）'
        );
        return;
      }
      if (s.kind === 'done') {
        api.mountBars(barsEl, s.arr);
        paintKept(barsEl, s.arr.length, []);
        api.setCaption(
          '完了: 残った列は非減少（要素数 ' + s.arr.length + '）'
        );
      }
    },
    stepPauseMs: 320,
  });
});
</script>
{% endcapture %}

{% include sort-demo.html
  id="stalin-sort-demo"
  data_prefix="stalin"
  script=sort_demo_js
%}

## 類似アルゴリズムとの相違点

[ボゴソート](/2026/07/24/sort-bogo.html)や[ボゾソート](/2026/07/25/sort-bozo.html)は入力の並べ替えを何度も試し、最終的には元の要素をすべて含む昇順列を目指す。スターリンソートは試行を重ねず、合わない要素を捨てて一発で「整って見える」列を作る点が対照的である。

[スリープソート](/2026/07/23/sort-sleep.html)や[スパゲッティソート](/2026/09/09/sort-spaghetti.html)もジョーク枠だが、いずれも入力の要素を結果に残す（物理量や待ち時間に写す）点がスターリンソートと異なる。

[選択ソート](/2026/05/11/sort-selection.html)が未整列範囲から最小を選んで確定位置へ運ぶのに対し、スターリンソートは「運ぶ」操作がなく、条件を満たさない値を結果から消すだけである。[サイクルソート](/2026/05/25/sort-cycle.html)が書き込み回数を最小化するのに対し、こちらは「都合の悪い要素」そのものを捨てる極端な簡略化である。
