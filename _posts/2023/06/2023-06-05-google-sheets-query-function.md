---
layout: post
title:  スプレッドシートでQUERY関数を使用する
date:   2023/06/05 12:08:58 +0900
tags:   google
---

## QUERY関数を使用する

QUERY関数を使用するとクエリ言語を用いて絞り込み、並び替え、集計が行える。フィルタよりも複雑な絞り込みや並び替えが可能。実行結果にさらにフィルタをかけたり、ピボットテーブルの作成を行うことは可能だが、並び替えはできない。

## 構文

```google
QUERY(データ, クエリ, [見出し])
```

### データ

クエリを実行する対象の配列または範囲。一つの列に数値と文字列のように違う型のデータが混ざっている場合多い方に変換され、変換できない場合はNULL（空欄）になってしまうため注意。

### クエリ

Google Visualization APIのクエリ言語で記述されたクエリ。リンク先に仕様がまとまっているが、Google Sheets専用の言語ではないためGoogle Sheetsで使用する場合には意味のない仕様がいくつかある（Google Sheetsでは列IDは常にアルファベット1文字か2文字の列番号で変更できない）。

### 見出し

データのうち見出しのある行数。省略または-1を指定した場合は型から推測される。2以上をしてした場合はスペース区切りで結合したものが1行目に表示される。