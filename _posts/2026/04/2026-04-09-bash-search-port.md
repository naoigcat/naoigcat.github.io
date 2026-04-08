---
layout: post
title:  空きポートを検索する
date:   2026/04/09 00:37:06 +0900
tags:   bash
---

## 通信に割り当てるポートの範囲が事前に定義されている

インターネットプロトコル（IP）を用いた通信を行うため、TCP/IPプロトコルスタックが事前に定義されている範囲内から自動的に割り当てるポートをエフェメラルポートという。

[RFC 6056](https://www.rfc-editor.org/rfc/rfc6056)ではポート番号1024から65535までの範囲を使うよう提言されている。

## 自動割り当て可能なポートの範囲を取得する

Linuxでは`/proc/sys/net/ipv4/ip_local_port_range`でエフェメラルポートの範囲を取得できる。

```bash
$ docker run -it debian:bookworm cat /proc/sys/net/ipv4/ip_local_port_range
32768   60999
```

macOSでは`sysctl`コマンドでエフェメラルポートの範囲を取得できる。

```bash
$ sysctl net.inet.ip.portrange.first net.inet.ip.portrange.last
net.inet.ip.portrange.first: 49152
net.inet.ip.portrange.last: 65535
```

## ランダムなポートを取得する

Linuxでは`shuf`コマンドでランダムなポートを取得できる。

```bash
$ docker run -it debian:bookworm sh -c "shuf -i \$(cat /proc/sys/net/ipv4/ip_local_port_range | awk '{print \$1 \"-\" \$2}') -n 1"
51234
```

macOSでは`jot`コマンドでランダムなポートを取得できる。

```bash
$ jot -r 1 $(sysctl net.inet.ip.portrange.first | awk '{print $2}') $(sysctl net.inet.ip.portrange.last | awk '{print $2}')
51234
```

## 自動割り当て可能なポートの範囲内で空きポートを検索する

`ss`コマンドはソケットの統計情報を表示するコマンドで`netstat`コマンドと同様の情報を表示でき、使用中のソケットが返されるため空きポートの検索に使用できる。

```bash
$ docker run -it debian:bookworm sh -c "\
    apt-get update && apt-get install -y --no-install-recommends iproute2 ; \
    for port in \$(shuf -i \$(cat /proc/sys/net/ipv4/ip_local_port_range | awk '{print \$1 \"-\" \$2}') -n 100) ; \
    do ss -H -ltn \"sport = :\$port\" | grep -q . > /dev/null || break ; done ; \
    echo \$port"
51234
```

`nc`コマンドはネットワーク診断ツールでポートが使用中かどうかを確認できる。

```bash
$ docker run -it debian:bookworm sh -c "\
    apt-get update && apt-get install -y --no-install-recommends netcat-openbsd ; \
    for port in \$(shuf -i \$(cat /proc/sys/net/ipv4/ip_local_port_range | awk '{print \$1 \"-\" \$2}') -n 100) ; \
    do nc -z localhost \$port > /dev/null || break ; done ; \
    echo \$port"
51234
```

macOSでは`netstat`コマンドと`nc`コマンドが標準搭載されているため空きポートの検索に使用できる。

```bash
for port in $(jot -r 100 $(sysctl net.inet.ip.portrange.first | awk '{print $2}') $(sysctl net.inet.ip.portrange.last | awk '{print $2}'))
do
    netstat -a -n | grep "\*\.$port.*LISTEN" > /dev/null || break
done
echo $port
```

```bash
for port in $(jot -r 100 $(sysctl net.inet.ip.portrange.first | awk '{print $2}') $(sysctl net.inet.ip.portrange.last | awk '{print $2}'))
do
    nc -z localhost $port > /dev/null || break
done
echo $port
```
