---
layout: post
title:  Dockerコンテナでdnsmasqを立ち上げる
date:   2024/12/19 14:24:08 +0900
tags:   docker
---

## ブラウザからローカル開発環境にドメインでアクセスする

ブラウザからローカル開発環境のサーバーにドメインを指定してアクセスする場合は/etc/hostsに追記することで可能になる。

```sh
echo '127.0.0.1       example-app.test' | sudo tee -a /etc/hosts
```

## ネイティブアプリからローカル開発環境にドメインでアクセスする

ネイティアプリからローカル開発環境のサーバーにドメインをしてアクセスする場合はサーバーを起動している端末をDNSサーバーにすることで可能になる。

Dockerでdnsmasqサービスを立ち上げ、ローカルの/etc/hostsからマッピングを生成することで実現する。ローカルのIPアドレスが変わるたびに再ビルドが必要になる。

```sh
> compose.yaml <<COMPOSE
services:
  dnsmasq:
    build:
      dockerfile_inline: |-
        FROM alpine:3.11
        ARG LOCAL_IP
        COPY hosts /root/hosts
        RUN apk --no-cache add dnsmasq && \\
            { \\
              echo "bogus-priv" ; \\
              echo "cache-size=0" ; \\
              echo "log-queries" ; \\
              echo "log-facility=/dev/stdout" ; \\
              echo "no-hosts" ; \\
              grep 127.0.0.1 /root/hosts | grep -v localhost | awk "{print \\"address=/\\"\\\$2\\"/\$\${LOCAL_IP}\\"}" ; \\
            } > /etc/dnsmasq.conf && \\
            { \\
              echo "#!/usr/bin/env sh" ; \\
              echo "grep address= /etc/dnsmasq.conf | awk -F'/' '{printf \\"%-16s %s\\\\n\\",\\\$3,\\\$2}'" ; \\
              echo "dnsmasq -k" ; \\
            } > /bin/docker-entrypoint.sh && \\
            chmod 755 /bin/docker-entrypoint.sh
        EXPOSE 53 53/udp
        ENTRYPOINT ["/bin/docker-entrypoint.sh"]
    platform: linux/x86_64
    environment:
      TZ: "Asia/Tokyo"
    ports:
      - "53:53/udp"
    cap_add:
      - NET_ADMIN
COMPOSE
cp /etc/hosts hosts
docker compose build --build-arg LOCAL_IP="$(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | head -n 1 | awk '{print $2}' | sed -e 's/addr://')"
docker compose up
```
