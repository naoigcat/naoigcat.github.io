---
layout: post
title:  Fastlaneでのコンパイル時に警告を抑制する
date:   2023/01/05 12:15:15 +0900
tags:   xcode fastlane
---

## CIビルド時に警告メッセージが多いとログが見辛い

CIでビルドするとき警告メッセージが大量に表示されるとログが追い辛くなる。CocoaPodsライブラリなど警告メッセージが必要ない部分が含まれることも多い。

## オプションで警告を抑制する

`xcargs`で`-suppress-warnings`を渡すことで警告を抑制することができる。

```ruby
# Fastfile
gym(
  xcargs: "OTHER_SWIFT_FLAGS='$(inherited) -suppress-warnings'",
)
```
