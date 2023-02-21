---
layout: post
title:  警告"libobjc.A.dylib is being read from process memory."が発生する
date:   2023/02/21 12:02:24 +0900
tags:   xcode
---

## ビルド時に警告が表示されることがある

Xcodeでのビルド時に以下の警告が表示され、アプリが起動しない場合がある。

```log
(lldb) warning: libobjc.A.dylib is being read from process memory.
This indicates that LLDB could not find the on-disk shared cache for this device.
This will likely reduce debugging performance.
```

## デバイスサポートファイルのリセットで解消する

下記コマンドでデバイスサポートファイルを削除してからXcodeを再起動することで解消される。

```sh
rm -r ~/Library/Developer/Xcode/iOS\ DeviceSupport
```

## ライブラリがロードされていないことで発生する

macOS上のLLDBにアプリとライブラリをロードすることでシンボリック化を行い、デバッグ時の実行箇所の特定や変数の解決を行っているが、何かしらの理由でライブラリがロードされていない場合、iOS/iPadOS端末と`gdb-remote protocol`での通信を行う必要がある。

通信を行うとmacOS上で処理するより時間がかかるためパフォーマンス劣化に繋がる。
