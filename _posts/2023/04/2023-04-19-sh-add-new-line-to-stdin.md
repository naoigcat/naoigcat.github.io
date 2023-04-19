---
layout: post
title:  標準入力の末尾に改行を付加する
date:   2023/04/19 16:02:05 +0900
tags:   sh
---

## 標準入力の末尾に改行を付加する

`awk 1`コマンドは標準入力をそのまま出力するが`awk`の性質上末尾に改行がない場合は改行を付加される。

```sh
$ printf 'message'
message%
$ printf 'message' | awk 1
message
$ printf 'message\n'
message
$ printf 'message\n' | awk 1
message
```
