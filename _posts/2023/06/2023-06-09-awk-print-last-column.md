---
layout: post
title:  AWKで最後のフィールドのみ出力する
date:   2023/06/09 13:22:40 +0900
tags:   awk
---

## 最後のフィールドのみ出力する

AWKで最後のフィールドは`$NF`で表現される。

```sh
$ echo $'1 2 3\n4 5 6' | awk '{print $NF}'
3
6
```

## 最後の行のみ出力する

AWKで最後の行は`END`で表現される。

```sh
$ echo $'1 2 3\n4 5 6' | awk 'END{print}'
4 5 6
```
