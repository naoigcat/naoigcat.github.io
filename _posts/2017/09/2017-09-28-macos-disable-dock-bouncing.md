---
title:     Dockのアイコンが跳ねるアクションを無効にする
date:      2017-09-28 09:58:00 +0900
tags:      macos
---

## 跳ねるアクションを無効にする

Dock上のアプリがアラート通知を受けたときに跳ねる動作を停止する。

```sh
defaults write com.apple.dock no-bouncing -boolean true
killall Dock
```
