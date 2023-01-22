---
layout: post
title:  MacのSpotlightのインデックスを再構築する
date:   2020/03/06 12:06:11 +0900
tags:   macos
---

Rubyの`xcode-install` gemでインストール済みのXcodeのバージョンを取得する場合、内部的には

```sh
mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'"
```

というコマンドを実行しているがSpotlightのインデックスに正しく含まれていないと検索されない。

Xcode.appのパスを指定して下記コマンドを実行した時に`kMDItemCFBundleIdentifier = "com.apple.dt.Xcode"`というレスポンスが得られているのにインストール済みのXcodeのリストに含まれなかった場合は、Spotlightのインデックスが正しくっ構築されていないことになる。

```sh
mdls -name kMDItemCFBundleIdentifier /Applications/Xcode.app
```

インデックスの再構築は下記コマンドで実行できる。

```sh
sudo mdutil -E /
sudo mdutil -i on /
```
