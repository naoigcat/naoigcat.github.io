---
layout: post
title:  ハッシュを使用してファイル名を変更する
date:   2020/11/12 16:37:18 +0900
tags:   sh
---

## ファイル名がユニークになるように変更する

```sh
for file in *.*; do mv $file "$(md5 "$file" | cut -d' ' -f4).${file##*.}"; done
```
