---
layout: post
title:  シミュレーターでステージマネージャーを有効化する
date:   2023/03/29 12:03:21 +0900
tags:   xcode ios
---

## [ステージマネージャーのオン／オフを切り替える](https://support.apple.com/ja-jp/HT213405)

### コントロールセンターから

1.  画面の右上隅から下にスワイプしてコントロールセンターを開く
1.  ステージマネージャーのボタン
    ![stage-manager-icon](https://support.apple.com/library/content/dam/edam/applecare/images/en_US/il/ipados-16-control-center-stage-manager-icon.png){:height="18px"}
    をタップする

### 設定アプリから

1.  設定アプリを開く
1.  「ホーム画面とマルチタスク」をタップして「ステージマネージャ」をタップする
1.  「iPad でステージマネージャを使用」のオン／オフを切り替える

## 新しいiPadでステージマネージャーが使用できる

以下のモデルでステージマネージャーが使用できる。

-   iPad Pro 12.9-inch (3rd generation or later)
-   iPad Pro 11-inch (1st generation or later)
-   iPad Air (5th generation or later)

iPadOS 16.2以降かつ以下のモデルでは外付けのディスプレイにアプリやウィンドウを移動できる

-   iPad Pro 12.9-inch (5th generation or later)
-   iPad Pro 11-inch (3rd generation or later)
-   iPad Air (5th generation or later)

## シミュレーターでステージマネージャーを有効化する

シミュレーターではコントロールセンターが使用できないため設定アプリから有効にするか設定ファイルを直接書き換えることで有効化できる。

```sh
defaults write ~/Library/Developer/CoreSimulator/Devices/{UUID}/data/Library/Preferences/.GlobalDefaults.plist SBChamoisWindowingEnabled -bool true
```
