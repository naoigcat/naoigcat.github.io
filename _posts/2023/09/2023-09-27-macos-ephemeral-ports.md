---
layout: post
title:  一時的に使用可能なポートの範囲を取得する
date:   2023/09/27 12:14:47 +0900
tags:   macos
---

## macOSで一時的に使用可能なポートの範囲を取得する

```sh
$ sysctl net.inet.ip.portrange.first net.inet.ip.portrange.last
net.inet.ip.portrange.first: 49152
net.inet.ip.portrange.last: 65535
```

## Linuxで一時的に使用可能なポートの範囲を取得する

```sh
$ docker run --rm ubuntu:latest cat /proc/sys/net/ipv4/ip_local_port_range
32768   60999
```
