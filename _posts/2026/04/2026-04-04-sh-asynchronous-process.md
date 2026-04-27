---
layout: post
title:  シェルスクリプトで非同期処理を行いつつ実行結果を受け取る
date:   2026/04/04 21:21:30 +0900
tags:   bash
---

## コマンドをバックグラウンドで実行する

シェルスクリプトでコマンドをバックグラウンドで実行するには、コマンドの末尾に`&`を付ける。

```bash
command &
```

バックグラウンドで実行したプロセスの終了を待つには、`wait`コマンドを使用する。

```bash
wait
```

受け取れるのはプロセスの終了コードのみで、標準出力や標準エラーはそのままでは受け取ることができない。

標準出力や標準エラーを受け取るには、プロセスの出力をファイルにリダイレクトしておき、`wait`の後でそのファイルを読み取る必要がある。

```bash
command > output.txt 2>&1 &
wait
cat output.txt
```

もしくは、名前付きパイプ（FIFO）を使用して、リアルタイムで出力を受け取ることもできる。

```bash
mkfifo mypipe
command > mypipe 2>&1 &
while read line; do
    echo "Output: $line"
done < mypipe
wait
```

## プロセス置換を使用して非同期処理の出力を受け取る

プロセス置換と`exec`を組み合わせることで、非同期処理の出力を直接受け取ることもできる。

```bash
exec 3< <(command)
while read -u 3 line; do
    echo "Output: $line"
done
```
