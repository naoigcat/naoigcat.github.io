---
layout: post
title:  Xcode 14.xでRosettaを有効にしたシミュレーター向けにビルドする
date:   2023/05/31 13:31:22 +0900
tags:   xcode
---

## Xcode 12.0 以降でRosettaをサポートしている

Apple Silicon 搭載のMacコンピュータではmacOS 11 Big Sur以降がインストール可能だが、対応しているXcodeは12.0以降になる。

Xcode 12以降はRosettaをサポートしており、Xcode 12を起動するため有効にする必要がある。

## [Xcode 14.3](https://developer.apple.com/documentation/xcode-release-notes/xcode-14_3-release-notes) 以降でRosettaはサポートされない

> Xcode isn’t supported under Rosetta.

Xcode 14.3 でRosettaのサポートがなくなっているためRosettaを有効にしてXcodeを起動することはできなくなっている。

## [Xcode 14.0](https://developer.apple.com/documentation/xcode-release-notes/xcode-14-release-notes) 以降でシミュレーターを使用する

> You can now boot simulator devices using universal runtimes as x86_64 on a Mac with Apple silicon by using the new --arch command-line argument to simctl boot.

Product > Destination > Destination Architectures でRosettaを有効になっているシミュレーターと無効になっているシミュレーターをそれぞれの表示を切り替えられる。
