---
layout: post
title:  .ipaファイルからプロビジョニングプロファイルを抽出する
date:   2020/04/23 09:35:20 +0900
tags:   ios
---

以下のコマンドで.ipaファイルに含まれているプロビジョニングプロファイルの内容を確認できる。

```sh
unzip "$PRODUCT_NAME.ipa"
security cms -D -i "Payload/$PRODUCT_NAME.app/embedded.mobileprovision"
```
