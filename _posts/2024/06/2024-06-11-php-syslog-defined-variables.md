---
layout: post
title:  PHPの定義済み定数の値を確認する
date:   2024/06/11 14:23:59 +0900
tags:   php
---

## 定義済みの定数を確認する

PHPのコアに[定義済みの定数](https://www.php.net/manual/ja/network.constants.php)としてsyslog()プロパティが含まれている。

PHP 5.3の時点で利用でき、現在でも値は変更されていない。

```sh
$ docker --version
Docker version 26.1.1, build 4cf5afa

$ docker run --rm --platform=linux/amd64 centos:7.0.1406 bash -c "yum install -y glibc-headers 2>/dev/null && cat /usr/include/sys/syslog.h" > $TMPDIR/syslog.h
$ grep -e "^#define\tLOG.*\t[0-9]\t" $TMPDIR/syslog.h

#define LOG_EMERG       0       /* system is unusable */
#define LOG_ALERT       1       /* action must be taken immediately */
#define LOG_CRIT        2       /* critical conditions */
#define LOG_ERR         3       /* error conditions */
#define LOG_WARNING     4       /* warning conditions */
#define LOG_NOTICE      5       /* normal but significant condition */
#define LOG_INFO        6       /* informational */
#define LOG_DEBUG       7       /* debug-level messages */

$ for var in $(grep -e "^#define\tLOG.*\t[0-9]\t" $TMPDIR/syslog.h | cut -f2)
do
    docker run --rm --platform=linux/amd64 php:5.3.29 php -r "echo '$var=' . $var . PHP_EOL;"
done

LOG_EMERG=0
LOG_ALERT=1
LOG_CRIT=2
LOG_ERR=3
LOG_WARNING=4
LOG_NOTICE=5
LOG_INFO=6
LOG_DEBUG=7
```

-   php:5.3.29のイメージは形式が古いためDocker Desktop 4.25.2以前でないと起動できない
