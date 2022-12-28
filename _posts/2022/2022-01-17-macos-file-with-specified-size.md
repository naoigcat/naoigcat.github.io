---
layout: post
title:  macOSで指定したサイズのダミーファイルを作成する
date:   2022/01/17 08:30:14 +0900
tags:   macos sh
---

下記コマンドで指定したサイズのファイルを作成できる。

```sh
mkfile 1k filename
```

単位は`b` (Bytes), `k` (KB), `m` (MB), `g` (GB)が指定できる。
