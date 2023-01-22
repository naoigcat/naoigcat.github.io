---
layout: post
title:  Bonjourを監視する
date:   2017-09-29 09:55:00 +0900
tags:   sh
---

LAN内のBonjourで配信されているサーバーを監視する

```sh
dns-sd -B _http._tcp
```
