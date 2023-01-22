---
layout: post
title:  ハッシュを使用してファイル名を変更する
date:   2020/11/12 16:37:18 +0900
tags:   sh
---

下記のスクリプトでファイル名がユニークになるようにハッシュを用いて変更できる。

```sh
for file in *.*; do mv $file "$(md5 "$file" | cut -d' ' -f4).${file##*.}"; done
```
