---
layout: post
title:  DNSサーバーを変更する
date:   2025/01/03 06:48:40 +0900
tags:   network
---

## シェルコマンドでDNSサーバーを変更する

下記コマンドでWi-Fi接続時のDNSサーバーを設定できる。

```sh
$ networksetup -setdnsservers Wi-Fi 8.8.8.8 8.8.4.4
$ scutil --dns | grep -A 4 '^DNS configuration$' | grep nameserver | awk '{print $3}' | tr '\n' ' '
8.8.8.8 8.8.4.4
```
