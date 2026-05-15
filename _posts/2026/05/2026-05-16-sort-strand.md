---
title:     ストランドソートで配列を並び替える
date:      2026-05-16 04:15:53 +0900
tags:      sort
sort_demo: true
---

## ストランドソートを使用する

ストランドソート (`strand sort`) は、未整列の区間を左から一度走査し、**先頭から続く単調非減少部分列（ストランド）**だけを抜き取り、それをすでに得られている整列済みの結果と **マージ（併合）** することを繰り返す比較ソートである。「麻ひも・繊維束（strand）をほどく」イメージで、1 本のストランドをずつ取り出して束ね直していく。

1.  **初期化**: 整列済み結果 `R` は空、`P` に入力をそのまま置く。
2.  **ストランド抽出**: `P` を左から見て、直前にストランドへ入れた末尾の値 **以上** の要素だけを順にストランドへ移す（末尾より小さい値は見送り、インデックスだけ進める）。1 回の走査でストランドは必ず 1 要素以上になる。
3.  **マージ**: `R` とストランドはどちらも昇順なので、マージソートと同様に先頭同士を比較しながら併合し、新しい `R` とする。`P` に残った要素はそのまま次のラウンドへ。
4.  **終了**: `P` が空になるまで手順 2〜3 を繰り返す。

最悪では 1 要素ずつしかストランドが伸びず、マージは合計で O(n²) 相当になる。マージを **安定** に実装（同値では常に `R` 側を先に取るなど）すれば、全体も安定ソートにできる。ストランドの取り出しとマージの双方で **追加配列** を使う実装が一般的で、空間計算量は実装次第だが O(n) 程度を要しやすい。

```pseudocode
procedure strand_sort(input)
  R = empty list
  P = copy of input
  while P is not empty
    strand = empty list
    i = 0
    while i < length(P)
      if strand is empty or P[i] >= last(strand) then
        append P[i] to strand
        remove P[i] from P
      else
        i = i + 1
    R = merge(R, strand) // both sorted; stable if merge breaks ties toward R
  return R
```

{% capture sort_demo_js %}
<script>
window.DemoSort && DemoSort.boot('strand-sort-demo', function (root) {
  function layoutRoles(mergedLen, strandLen, extraPairs) {
    const pairs = [];
    for (let k = 0; k < mergedLen; k++) {
      pairs.push([k, 'sorted']);
    }
    for (let k = 0; k < strandLen; k++) {
      pairs.push([mergedLen + k, 'range']);
    }
    if (extraPairs) {
      for (let e = 0; e < extraPairs.length; e++) {
        pairs.push(extraPairs[e]);
      }
    }
    return pairs;
  }

  function rangePairs(lo, hi, role) {
    const pairs = [];
    for (let k = lo; k <= hi; k++) {
      pairs.push([k, role]);
    }
    return pairs;
  }

  function displayArr(merged, strand, pending) {
    return merged.concat(strand).concat(pending);
  }

  function generateSteps(initial) {
    const steps = [];
    let merged = [];
    let pending = initial.slice();

    function mergeRecord(mergedIn, strandIn, pendingIn) {
      const m = mergedIn.length;
      const s = strandIn.length;
      const lo = 0;
      const mid = m - 1;
      const hi = m + s - 1;
      const w = mergedIn.concat(strandIn).concat(pendingIn);
      steps.push({
        kind: 'merge_start',
        lo: lo,
        mid: mid,
        hi: hi,
        arr: w.slice(),
      });
      const tmp = [];
      function buildDisplay() {
        const d = w.slice();
        for (let t = 0; t < tmp.length; t++) {
          d[lo + t] = tmp[t];
        }
        return d;
      }
      let i = 0;
      let j = m;
      while (i <= mid && j <= hi) {
        steps.push({
          kind: 'merge_compare',
          i: i,
          j: j,
          arr: buildDisplay(),
        });
        if (w[i] <= w[j]) {
          tmp.push(w[i++]);
        } else {
          tmp.push(w[j++]);
        }
        steps.push({
          kind: 'merge_write',
          writePos: lo + tmp.length - 1,
          lo: lo,
          hi: hi,
          arr: buildDisplay(),
        });
      }
      while (i <= mid) {
        tmp.push(w[i++]);
        steps.push({
          kind: 'merge_write',
          writePos: lo + tmp.length - 1,
          lo: lo,
          hi: hi,
          arr: buildDisplay(),
        });
      }
      while (j <= hi) {
        tmp.push(w[j++]);
        steps.push({
          kind: 'merge_write',
          writePos: lo + tmp.length - 1,
          lo: lo,
          hi: hi,
          arr: buildDisplay(),
        });
      }
      for (let t = 0; t < tmp.length; t++) {
        w[lo + t] = tmp[t];
      }
      steps.push({
        kind: 'merge_done',
        lo: lo,
        hi: hi,
        arr: w.slice(),
      });
      return {
        merged: w.slice(0, m + s),
        pending: w.slice(m + s),
      };
    }

    if (pending.length === 0) {
      steps.push({ kind: 'done', arr: [] });
      return steps;
    }

    while (pending.length > 0) {
      const mergedLenStart = merged.length;
      steps.push({
        kind: 'round_start',
        mergedLen: mergedLenStart,
        arr: displayArr(merged, [], pending),
      });
      const strand = [];
      let i = 0;
      while (i < pending.length) {
        const m = merged.length;
        const s = strand.length;
        const candidateIdx = m + s + i;
        const val = pending[i];
        if (strand.length === 0 || val >= strand[strand.length - 1]) {
          if (strand.length > 0) {
            const strandEndIdx = m + s - 1;
            steps.push({
              kind: 'strand_pre_take',
              mergedLen: m,
              strandLen: s,
              candidateIdx: candidateIdx,
              strandEndIdx: strandEndIdx,
              arr: displayArr(merged, strand, pending),
            });
          } else {
            steps.push({
              kind: 'strand_pre_take_first',
              mergedLen: m,
              strandLen: s,
              candidateIdx: candidateIdx,
              arr: displayArr(merged, strand, pending),
            });
          }
          strand.push(val);
          pending.splice(i, 1);
          steps.push({
            kind: 'strand_taken',
            mergedLen: m,
            strandLen: strand.length,
            arr: displayArr(merged, strand, pending),
          });
        } else {
          steps.push({
            kind: 'strand_skip',
            mergedLen: m,
            strandLen: s,
            skipIdx: candidateIdx,
            arr: displayArr(merged, strand, pending),
          });
          i++;
        }
      }
      const out = mergeRecord(merged, strand, pending);
      merged = out.merged;
      pending = out.pending;
    }

    steps.push({
      kind: 'done',
      arr: displayArr(merged, [], pending),
    });
    return steps;
  }

  DemoSort.attachPlayback({
    root: root,
    dataAttr: 'data-strand',
    initialValues: [5, 2, 8, 1, 9, 3, 6, 14, 4, 11, 7, 13, 10, 12, 15],
    initialCaption:
      'ストランドソートのデモ（紫＝マージ済み、青＝今取り出しているストランド、比較はオレンジ、マージ書き込みは緑）',
    barClass: 'sort-demo__bar',
    generateSteps: generateSteps,
    applyStep: async function (api, s) {
      const barsEl = api.barsEl;
      if (s.kind === 'round_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, layoutRoles(s.mergedLen, 0, []));
        api.setCaption(
          'ラウンド開始: 左（紫）はマージで確定済み。未処理列からストランドを取り出します'
        );
        return;
      }
      if (s.kind === 'strand_pre_take_first') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(
          barsEl,
          layoutRoles(s.mergedLen, s.strandLen, [[s.candidateIdx, 'compare']])
        );
        api.setCaption(
          'ストランド先頭として取り込みます（位置 ' + s.candidateIdx + '）'
        );
        return;
      }
      if (s.kind === 'strand_pre_take') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(
          barsEl,
          layoutRoles(s.mergedLen, s.strandLen, [
            [s.candidateIdx, 'compare'],
            [s.strandEndIdx, 'compare'],
          ])
        );
        api.setCaption(
          '比較: 候補（位置 ' +
            s.candidateIdx +
            '）はストランド末尾以上なので取り込みます'
        );
        return;
      }
      if (s.kind === 'strand_taken') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(
          barsEl,
          layoutRoles(s.mergedLen, s.strandLen, [
            [s.mergedLen + s.strandLen - 1, 'write'],
          ])
        );
        api.setCaption('ストランドに要素を追加しました');
        return;
      }
      if (s.kind === 'strand_skip') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(
          barsEl,
          layoutRoles(s.mergedLen, s.strandLen, [[s.skipIdx, 'compare']])
        );
        api.setCaption(
          '見送り: 位置 ' +
            s.skipIdx +
            ' はストランド末尾より小さいのでこのラウンドでは取りません'
        );
        return;
      }
      if (s.kind === 'merge_start') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, rangePairs(s.lo, s.hi, 'range'));
        if (s.mid < s.lo) {
          api.setCaption(
            'マージ: 確定済みが空のため、今回のストランドだけが新しい確定列になります'
          );
        } else {
          api.setCaption(
            'マージ: 確定済みと今回のストランドを併合します [' +
              s.lo +
              '…' +
              s.mid +
              '] と [' +
              (s.mid + 1) +
              '…' +
              s.hi +
              ']'
          );
        }
        return;
      }
      if (s.kind === 'merge_compare') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.i, 'compare'], [s.j, 'compare']]);
        api.setCaption('マージ比較: 位置 ' + s.i + ' と ' + s.j);
        return;
      }
      if (s.kind === 'merge_write') {
        api.mountBars(barsEl, s.arr);
        DemoSort.assignRoles(barsEl, [[s.writePos, 'write']]);
        api.setCaption('マージ: 位置 ' + s.writePos + ' に小さい方を確定');
        return;
      }
      if (s.kind === 'merge_done') {
        api.mountBars(barsEl, s.arr);
        DemoSort.clearRoles(barsEl);
        api.setCaption(
          'マージ完了: 区間 ' + s.lo + ' … ' + s.hi + ' が昇順にまとまりました'
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

{% include sort-demo/wrapper.html
  id="strand-sort-demo"
  preset="strand"
  data_prefix="strand"
  script=sort_demo_js
%}

教育用・挙動の可視化にはわかりやすい一方、一般用途の標準ソートとしてはクイックソートやティムソートなどに比べ不利になりやすい。マージの性質を理解する教材として、マージソートと対比して読むと理解が進みやすい。
