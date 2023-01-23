---
layout: post
title:  コマンドラインでmacOSのシリアル番号を取得する
date:   2020/03/22 09:46:07 +0900
tags:   macos
---

## コマンドでシリアル番号を確認する

メニューの`このMacについて`からシリアル番号は確認できるが、以下のコマンドでも確認できる。

```sh
/usr/sbin/ioreg -l | grep IOPlatformSerialNumber | awk -F' = ' '{print $2}' | tr -d '"'
```
