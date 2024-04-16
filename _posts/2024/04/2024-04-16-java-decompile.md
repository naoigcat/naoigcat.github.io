---
layout: post
title:  Java製ソフトウェアを逆コンパイルする
date:   2024/04/16 16:40:55 +0900
tags:   java
---

## [JADX](https://github.com/skylot/jadx)を利用して逆コンパイルする

JADXはArchLinuxで簡単にインストールできるためDockerイメージに利用したいバージョンのJDKを入れてインストールすることで実行可能な環境を作れる。

```yaml
services:
  jadx:
    build:
      dockerfile_inline: |
        FROM --platform=linux/amd64 archlinux:base-20240101.0.204074
        RUN pacman -Syy --noconfirm jdk11-openjdk jadx
        ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk
        WORKDIR /work
        ENTRYPOINT ["jadx"]
    volumes:
      - .:/work
```

コマンドを実行することで指定したディレクトリに逆コンパイルしたコードが出力される。

```sh
$ docker compose run --build --rm jadx -d output app.apk
INFO  - loading ...
INFO  - processing ...
INFO  - done
```
