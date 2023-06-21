---
layout: post
title:  Xcodeからのデバッグ実行で実機がビジーになる
date:   2023/06/21 12:07:05 +0900
tags:   xcode
---

## デバッグ実行で実機がビジーになる場合がある

実機でデバッグ実行しようとしたときに下記のエラーでいつまで経ってもアプリが起動しないことがある。

```stderr
Error: <デバイス名> is busy: Copying cache files from device. Xcode will continue when <デバイス名> is finished. (code -10)
```

## キャッシュの削除で解消する

DerivedDataを全て削除すると解消される。

```sh
rm -fr ~/Library/Developer/Xcode/DerivedData
```
