---
layout: post
title:  ランダムな数字を生成する
date:   2026/04/10 22:05:36 +0900
tags:   bash
---

## ランダムな数字をコマンドで生成する

Bashの組み込み定数 `$RANDOM` を使うと、0〜32767のランダムな整数を簡単に取得できる。

```bash
echo $(( $RANDOM % 100 + 1 ))
```

Bash 5.1以降には、従来の `$RANDOM` よりも暗号学的に安全な疑似乱数を返す `$SRANDOM` が追加されている。macOSの標準Bash（バージョン3.2）などでは利用できない。

```bash
echo $(( $SRANDOM % 100 + 1 ))
```

乱数生成デバイス `/dev/urandom` から4バイト読み出し、 `od` コマンドで符号なし10進数に変換することもできる。

```bash
od -vAn -N4 -tu4 < /dev/urandom | awk 'NF {print ($1 % 100) + 1}'
```

UNIXに標準搭載されている `awk` の `rand()` 関数を活用する方法もある。コマンド単体で動作するためポータビリティが高い。

```bash
awk 'BEGIN{srand(); print int(rand()*100)+1}'
```

スクリプト言語 `perl` でも組み込み関数でランダムな数字を生成できる。

```bash
perl -le 'print int(rand(100)) + 1'
```

スクリプト言語 `ruby` でも同様に組み込み関数でランダムな数字を生成できる。

```bash
ruby -e 'puts rand(1..100)'
```

macOSでは `jot` コマンドが標準で用意されている。 `-r` オプションでランダムなデータを出力でき、その後の引数で個数、最小値、最大値を指定する。

```bash
jot -r 1 1 100
```

Linuxでは `shuf` コマンドが使用できる。 `-i` で範囲を指定し、 `-n` で個数を指定する。macOSでは `coreutils` をインストールする（`brew install coreutils`）ことで `gshuf` コマンドとして利用できる。

```bash
docker run -i debian:bookworm shuf -i 1-100 -n 1
```
