---
layout: post
title:  iOSシミュレーターのUserDefaultsをリセットする
date:   2017-07-26 13:50:00 +0900
tags:   mac, ios
---

## 手順

Menu>Window>Devicesを開いてリセットしたいシミュレーターのIdentifierを確認する。

下記コードの`DEV`を先程確認したIdentifierに、`BID`をリセットしたいアプリのBundle Identifierに書き換えて実行する。

```sh
DEV=71C5E204-B117-427A-9F7B-B58E2338C270
BID=com.example.App
find ~/Library/Developer/CoreSimulator/Devices/$DEV/data/Containers/Data/Application -name $BID.plist
```

アプリを再起動するとUserDefaultsがクリアされた状態で起動する。

## 注意

シミュレーター上でアプリを削除することでもリセット可能だがその場合は端末ID`UUID`がリセットされてしまう。
