---
layout: post
title:  Docker Composeで起動するサービスを指定する
date:   2023/02/20 12:00:52 +0900
tags:   docker
---

## [サービスにプロファイルを設定する](https://docs.docker.com/compose/profiles/)

`docker-compose.yml`ファイルでサービスを定義するときに`profiles`に任意の名称を設定できる。

## プロファイルを指定せずに起動する

サービス起動時にプロファイルを指定しなかった場合はプロファイルが指定されていないサービスのみが起動する。

```sh
$ <<YAML > docker-compose.yml
version: '3.9'
services:
  web:
    image: php:fpm-alpine
    depends_on:
      - database
    profiles:
      - web
  admin:
    image: phpmyadmin:fpm-alpine
    depends_on:
      - database
    profiles:
      - admin
  database:
    image: mysql:latest
    environment:
      MYSQL_ALLOW_EMPTY_PASSWORD: true
YAML
$ docker compose up
# => start `database`
```

## プロファイルを指定して起動する

プロファイルを指定した場合は指定されたプロファイルとプロファイルが指定されていないサービスが起動する。

```sh
$ docker compose --profile web up
# => start `web`, `database`
```

```sh
$ COMPOSE_PROFILES=web docker compose up
# => start `web`, `database`
```

## プロファイルを複数指定して起動する

プロファイルは複数指定することができる。

```sh
$ docker compose --profile web --profile admin up
# => start `web`, `admin`, `database`
```

```sh
$ COMPOSE_PROFILES=web,admin docker compose up
# => start `web`, `admin, `database`
```
