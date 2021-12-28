---
layout: post
title:  Fastlaneの"A required agreement is missing or has expired"に対応する
date:   2021/12/28 12:47:47 +0900
tags:   xcode fastlane
---

Fastlane sighで証明書をダウンロードするとき、下記のようなエラーが発生する場合がある。

```log
A required agreement is missing or has expired. - This request requires an in-effect agreement that has not been signed or has expired.
```

これは、Apple Developer Program License Agreementが更新されていてApple Developerの管理画面で同意ボタンを押す必要があるときに発生する。

同意ボタンを押してからリトライすればエラーは解消する（反映まで少し時間がかかる模様）。
