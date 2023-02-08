---
layout: post
title:  macOSに付属しているmakeコマンドは古い
date:   2023/02/08 13:20:57 +0900
tags:   sh
---

## macOSに付属しているmakeコマンドは古い

|Release Date|OS          |make |
|:-----------|:-----------|:----|
|2017-06-05  |macos 10.13 |3.81 |
|2021-06-07  |macos 12    |3.81 |
|2011-07-10  |centos 6    |3.81 |
|2014-07-07  |centos 7    |3.82 |
|2019-09-24  |centos 8    |4.2.1|
|2014-04-17  |ubuntu 14.04|3.81 |
|2016-04-21  |ubuntu 16.04|4.1  |
|2018-04-26  |ubuntu 18.04|4.1  |
|2020-04-23  |ubuntu 20.04|4.2.1|
|2022-04-21  |ubuntu 22.04|4.3  |
|2011-02-06  |debian 6    |3.81 |
|2013-05-04  |debian 7    |3.81 |
|2015-04-25  |debian 8    |4.0  |
|2017-06-17  |debian 9    |4.1  |
|2019-07-06  |debian 10   |4.2.1|
|2021-08-14  |debian 11   |4.3  |
|2019-06-19  |alpine 3.10 |4.2.1|
|2019-12-29  |alpine 3.11 |4.2.1|
|2020-05-29  |alpine 3.12 |4.3  |
|2021-01-14  |alpine 3.13 |4.3  |
|2021-06-15  |alpine 3.14 |4.3  |
|2021-11-24  |alpine 3.15 |4.3  |
|2022-05-23  |alpine 3.16 |4.3  |
|2022-11-22  |alpine 3.17 |4.3  |

macOSに付属している`make`コマンドおよびXcodeに付属している`make`コマンドのバージョンは3.81で固定されていて更新されていない。

```sh
$ /usr/bin/make --version | head -n1
GNU Make 3.81
$ /Applications/Xcode.app/Contents/Developer/usr/bin/make --version | head -n1
GNU Make 3.81
```

Homebrewでは最新の`make`コマンドがインストールされる。

```sh
$ brew install make ; $(brew --prefix make)/libexec/gnubin/make --version | head -n1
GNU Make 4.4
```

Linuxディストリビューションでは`make`コマンドがデフォルトでインストールされておらず、デフォルトリポジトリからインストールできる`make`コマンドはディストリビューションのリリース当時の最新になる。

```sh
$ docker run --rm centos:6 bash -c 'yum update >/dev/null 2>&1 ; yum install -y make >/dev/null 2>&1 ; make --version | head -n1'
GNU Make 3.81
$ docker run --rm centos:7 bash -c 'yum update >/dev/null 2>&1 ; yum install -y make >/dev/null 2>&1 ; make --version | head -n1'
GNU Make 3.82
$ docker run --rm -i centos:8 bash <<SCRIPT
sed -i -e "s/^mirrorlist/#mirrorlist/g" -e "s/^#baseurl=http:\/\/mirror/baseurl=http:\/\/vault/g" /etc/yum.repos.d/CentOS-Linux-*.repo
yum update ; yum install -y make ; make --version | head -n1
SCRIPT
GNU Make 4.2.1
$ docker run --rm ubuntu:14.04 bash -c 'apt update >/dev/null 2>&1 ; apt install -y make >/dev/null 2>&1 ; make --version | head -n1'
GNU Make 3.81
$ docker run --rm ubuntu:16.04 bash -c 'apt update >/dev/null 2>&1 ; apt install -y make >/dev/null 2>&1 ; make --version | head -n1'
GNU Make 4.1
$ docker run --rm ubuntu:18.04 bash -c 'apt update >/dev/null 2>&1 ; apt install -y make >/dev/null 2>&1 ; make --version | head -n1'
GNU Make 4.1
$ docker run --rm ubuntu:20.04 bash -c 'apt update >/dev/null 2>&1 ; apt install -y make >/dev/null 2>&1 ; make --version | head -n1'
GNU Make 4.2.1
$ docker run --rm ubuntu:22.04 bash -c 'apt update >/dev/null 2>&1 ; apt install -y make >/dev/null 2>&1 ; make --version | head -n1'
GNU Make 4.3
$ docker run --rm -i debian:squeeze bash <<SCRIPT
{
    echo 'deb http://archive.debian.org/debian/ squeeze main non-free' ;
    echo 'deb-src http://archive.debian.org/debian/ squeeze main non-free' ;
} > /etc/apt/sources.list
apt-get update >/dev/null 2>&1
apt-get install --force-yes -y make >/dev/null 2>&1
make --version | head -n1
SCRIPT
GNU MAKE 3.81
$ docker run --rm -i debian:wheezy bash <<SCRIPT
{
    echo 'deb http://archive.debian.org/debian/ wheezy main non-free' ;
    echo 'deb-src http://archive.debian.org/debian/ wheezy main non-free' ;
} > /etc/apt/sources.list
apt-get update >/dev/null 2>&1
apt-get install --force-yes -y make >/dev/null 2>&1
make --version | head -n1
SCRIPT
GNU MAKE 3.81
$ docker run --rm debian:jessie bash -c 'apt update >/dev/null 2>&1 ; apt install --force-yes -y make >/dev/null 2>&1 ; make --version | head -n1'
GNU Make 4.0
$ docker run --rm debian:stretch bash -c 'apt update >/dev/null 2>&1 ; apt install -y make >/dev/null 2>&1 ; make --version | head -n1'
GNU Make 4.1
$ docker run --rm debian:buster bash -c 'apt update >/dev/null 2>&1 ; apt install -y make >/dev/null 2>&1 ; make --version | head -n1'
GNU Make 4.2.1
$ docker run --rm debian:bullseye bash -c 'apt update >/dev/null 2>&1 ; apt install -y make >/dev/null 2>&1 ; make --version | head -n1'
GNU Make 4.3
$ docker run --rm alpine:3.10 ash -c 'apk update >/dev/null ; apk add make >/dev/null ; make --version | head -n1'
GNU Make 4.2.1
$ docker run --rm alpine:3.11 ash -c 'apk update >/dev/null ; apk add make >/dev/null ; make --version | head -n1'
GNU Make 4.2.1
$ docker run --rm alpine:3.12 ash -c 'apk update >/dev/null ; apk add make >/dev/null ; make --version | head -n1'
GNU Make 4.3
$ docker run --rm alpine:3.13 ash -c 'apk update >/dev/null ; apk add make >/dev/null ; make --version | head -n1'
GNU Make 4.3
$ docker run --rm alpine:3.14 ash -c 'apk update >/dev/null ; apk add make >/dev/null ; make --version | head -n1'
GNU Make 4.3
$ docker run --rm alpine:3.15 ash -c 'apk update >/dev/null ; apk add make >/dev/null ; make --version | head -n1'
GNU Make 4.3
$ docker run --rm alpine:3.16 ash -c 'apk update >/dev/null ; apk add make >/dev/null ; make --version | head -n1'
GNU Make 4.3
$ docker run --rm alpine:3.17 ash -c 'apk update >/dev/null ; apk add make >/dev/null ; make --version | head -n1'
GNU Make 4.3
```
