---
layout: post
title:  Xcode13以降でビルド番号を自動的に更新しない
date:   2023/01/09 12:32:53 +0900
tags:   xcode fastlane
---

## ビルド番号のインクリメント機能が追加された

Xcode 13以降でApp Store Connectにアップロードするとき、既にアップロード済みのバイナリとビルド番号が衝突した場合、
自動的にインクリメントしてくれる機能が追加されている。

[Apple Xcode13 Release Note](https://developer.apple.com/documentation/xcode-release-notes/xcode-13-release-notes)

> -   When uploading an app to App Store Connect, the distribution assistant in Xcode detects whether your app has a valid build number (CFBundleVersion).
>     If your app has an invalid number (like one that was used previously, or precedes your current build number),
>     the distribution assistant provides an option to automatically increment it to a valid number. In addition,
>     the distribution assistant ensures that the build numbers of all embedded content in your app
>     (such as app extensions, App Clips, or watchOS apps) are in sync with your app.
>     Note that this doesn’t modify your source code or your archive;
>     Xcode updates the build number in a staged copy of your app before packaging and uploading it to App Store Connect. (59826409)

## 設定変更かオプション追加で無効化できる

App Store Connect distribution optionからManage Version and Build Numberをオフにすることで無効化できる。

xcodebuildコマンドを使用する場合は`exportOption`に`manageAppVersionAndBuildNumber: NO`を指定することで無効化できる。

```rb
gym(
  export_options: {
    manageAppVersionAndBuildNumber: false,
  },
)
```
