---
layout: post
title:  コマンド出力結果の行頭に日時を入れる
date:   2017/09/27 13:54:00 +0900
tags:   sh
---

`ping`コマンドを継続的に実行してネットワークの状態を監視するなど継続的に出力がある場合、
出力がいつ行われたか分からないため、行頭に日時を入れたい時がある。

```sh
ping 192.168.100.1 | while read line; do echo "$(date '+[%Y/%m/%d %H:%M:%S]') $line"; done
```

```output
[2017/09/27 14:31:31] PING 192.168.100.1 (192.168.100.1): 56 data bytes
[2017/09/27 14:31:31] 64 bytes from 192.168.100.1: icmp_seq=0 ttl=64 time=3.162 ms
[2017/09/27 14:31:32] 64 bytes from 192.168.100.1: icmp_seq=1 ttl=64 time=2.885 ms
[2017/09/27 14:31:33] 64 bytes from 192.168.100.1: icmp_seq=2 ttl=64 time=13.344 ms
```

`ping`コマンドの場合、macOSでは`--apple-time`のオプションも使用できる。

```sh
ping --apple-time 192.168.100.1
```

```output
PING 192.168.100.1 (192.168.100.1): 56 data bytes
14:34:49.965032 64 bytes from 192.168.100.1: icmp_seq=0 ttl=64 time=5.234 ms
14:34:50.972081 64 bytes from 192.168.100.1: icmp_seq=1 ttl=64 time=7.480 ms
14:34:51.969745 64 bytes from 192.168.100.1: icmp_seq=2 ttl=64 time=3.247 ms
```output
