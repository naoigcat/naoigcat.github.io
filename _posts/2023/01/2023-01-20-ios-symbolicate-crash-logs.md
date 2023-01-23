---
layout: post
title:  iOSのクラッシュログのファイル名・メソッド名・行数を復元する
date:   2023/01/20 12:35:41 +0900
tags:   ios
---

## アプリがクラッシュしたときにはログが保存される

iOSアプリがクラッシュした場合端末内にクラッシュログが保存される。

クラッシュログにはスタックトレースが含まれるがその内容はアドレスになっていて具体的にどのコードが実行されたかが分からないため、ファイル名と行数を復元する必要がある。

## 端末からクラッシュログを抽出する

iOS端末の下記の画面からアプリ名（`PRODUCT_NAME`に指定した名前）-日付.ips (.crash) のファイルを選択し、macOS端末に転送する。

|バージョン     |場所                                                                   |
|:--------------|:----------------------------------------------------------------------|
|iOS 16.x ~     |設定アプリ > プライバシーとセキュリティ > 解析および改善 > 解析データ　|
|iOS 13.x ~ 15.x|設定アプリ > プライバシー > 解析および改善 > 解析データ　　　　　　　　|
|iOS 10.3 ~ 12.x|設定アプリ > プライバシー > 解析 > 解析データ　　　　　　　　　　　　　|
|iOS 10.0 ~ 10.2|設定アプリ > プライバシー > 診断と使用状況 > 診断データと使用状況データ|

## クラッシュログを復元する

アプリをビルドしたときに生成される`.app.dSYM`ファイルを用意しておく。

XcodeやiOS/iPadOSのバージョンに応じて下記コマンドを実行することで.ips (.crash) ファイルのスタックトレース部分がアドレスではなく、ファイル名・メソッド名・行数が表示されるようになる。

### Xcode 7.0

```sh
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
export PATH=/Applications/Xcode.app/Contents/SharedFrameworks/DTDeviceKitBase.framework/Versions/A/Resources:$PATH
symbolicatecrash -v {APP}-{DATE}.ips {APP}.app.dSYM
```

### Xcode 7.3

```sh
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
export PATH=/Applications/Xcode.app/Contents/SharedFrameworks/DVTFoundation.framework/Versions/A/Resources:$PATH
symbolicatecrash -v {APP}-{DATE}.ips {APP}.app.dSYM
```

### Xcode 13 + iOS/iPadOS 15

```sh
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
export SYMBOLICATOR=/Applications/Xcode.app/Contents/SharedFrameworks/CoreSymbolicationDT.framework/Resources/CrashSymbolicator.py
python3 $SYMBOLICATOR -p {APP}-{DATE}.ips -d {APP}.app.dSYM
```

## フレームワーク部分が復元されない

iOS端末のOSに対応してデバイスサポートファイルがない場合、UIKitなどのフレームワーク部分が復元されない。

`~/Library/Developer/Xcode/iOS DeviceSupport/`に端末のOSバージョンに対応するディレクトリがない場合は、同じOSバージョンの端末を接続し、Xcodeでそのデバイスを選択することで自動的にダウンロードされる。
