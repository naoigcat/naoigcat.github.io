---
layout: post
title:  Bonjourで配信されているサーバーを監視する
date:   2017/09/29 09:55:00 +0900
tags:   sh
---

## 配信されているサーバーを監視する

LAN内のBonjourで配信されているサーバーを監視する

```sh
dns-sd -B _http._tcp
```
