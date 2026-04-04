---
layout: post
title:  シェルスクリプトでコマンドの結果の先頭行と末尾行を取得する
date:   2026/04/05 06:36:22 +0900
tags:   bash
---

## コマンドの結果の先頭行を取得する

`head`コマンドを使用して、コマンドの結果の先頭行を取得することができる。

```bash
seq 1 10 | head -n 1
```

## コマンドの結果の末尾行を取得する

`tail`コマンドを使用して、コマンドの結果の末尾行を取得することができる。

```bash
seq 1 10 | tail -n 1
```

## コマンドの結果の先頭行と末尾行を同時に取得する

`awk`コマンドを使用して、コマンドの結果の先頭行と末尾行を同時に取得することもできる。

```bash
seq 1 10 | awk 'NR==1 {first=$0} {last=$0} END {print "First line: " first; print "Last line: " last}'
```

`sed`コマンドを使用して、コマンドの結果の先頭行と末尾行を同時に取得することもできる。

```bash
seq 1 10 | sed -n '1s/^/First line: /p; $s/^/Last line: /p'
```

`read`と`tail`を組み合わせて、コマンドの結果の先頭行と末尾行を同時に取得することもできる。

```bash
seq 1 10 | { read first; last=$(tail -n 1); echo "First line: $first"; echo "Last line: $last"; }
```

## 読み込みバッファに注意する

`head`と`tail`を組み合わせた場合は`head`コマンドが全ての入力を読み込みバッファに保持してしまうため末尾行が取得できない。

```bash
seq 1 10 | head -n 1 | tail -n 1
```
