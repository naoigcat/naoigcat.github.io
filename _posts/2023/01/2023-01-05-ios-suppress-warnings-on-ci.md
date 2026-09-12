---
title:     Fastlaneでのコンパイル時に警告を抑制する
date:      2023-01-05 12:15:15 +0900
tags:      xcode fastlane
---

## CIビルド時に警告メッセージが多いとログが見づらい

CIでビルドするとき警告メッセージが大量に表示されるとログが追いづらくなる。CocoaPodsライブラリなど、警告メッセージが不要な部分が含まれることも多い。

## オプションで警告を抑制する

`xcargs`で`OTHER_SWIFT_FLAGS`に`-suppress-warnings`を渡すことで、Swift コンパイラ（フロントエンド）の警告を抑制できる。

CocoaPods 由来の Objective-C / C の警告は対象外なので、ログが見づらい場合は Pod 側のビルド設定など別途対応が必要になる。

```ruby
# Fastfile
gym(
  xcargs: "OTHER_SWIFT_FLAGS='$(inherited) -suppress-warnings'",
)
```
