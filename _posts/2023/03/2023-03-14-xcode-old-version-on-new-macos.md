---
layout: post
title:  新しいmacOSで古いXcodeを実行する
date:   2023/03/14 12:12:15 +0900
tags:   macos
---

## 最新のXcodeしか起動しなくなっている

macOS Big Sur 11 以降Xcodeは最新のバージョンしか起動せず、古いバージョンのXcodeを起動しようとすると下記のエラーメッセージが表示されて起動できない。

```txt
The version of Xcode installed on this Mac is not compatible with macOS Xxx.
Download the latest version for free from the App Store.
```

[Xcode 13.4.1のリリースノート](https://developer.apple.com/documentation/xcode-release-notes/xcode-13_4_1-release-notes)でも

> Note: macOS Ventura 13 only supports Xcode 14 beta.

と起動しないことが明記されている。

## コマンドラインから実行することで起動できる

下記のようにアプリケーションファイル内にある`Xcode`バイナリを直接実行することでアプリが起動できる。

```sh
/Applications/Xcode-11.7-GM.app/Contents/MacOS/Xcode # macOS Big Sur
/Applications/Xcode-12.5.1-GM.app/Contents/MacOS/Xcode # macOS Monterey
/Applications/Xcode-13.4.1-GM.app/Contents/MacOS/Xcode # macOS Ventura
```

実行後は実行したセッションにログが出力され、Ctrl+Cなどで終了させるとアプリも終了する。
