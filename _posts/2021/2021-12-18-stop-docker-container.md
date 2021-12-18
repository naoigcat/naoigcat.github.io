---
layout: post
title:  イメージ名からコンテナを停止する
date:   2021/12/18 13:39:52 +0900
tags:   shell docker
---

## コンテナ一覧の絞り込み

`docker ps`コマンドは[`--filter`オプション](https://docs.docker.jp/engine/reference/commandline/ps.html#ps-filtering)で絞り込みができる。

イメージ名で絞り込む場合は`ancestor`を使用する

```sh
docker ps --filter ancestor=ubuntu:latest
```

## コンテナ一覧出力時の整形

[`--format`オプション](https://docs.docker.jp/engine/reference/commandline/ps.html#ps-formatting)で整形できる。

{% raw %}

```sh
docker ps --format {{.ID}}
```

{% endraw %}

## 実行中のコンテナをイメージ名で停止させる

`docker stop`はコンテナIDを引数に取るためイメージ名しか分からない状態だと`docker ps`でコンテナIDを調べてから停止させることになる。

{% raw %}

```sh
docker stop $(docker ps --filter ancestor=ubuntu:latest --format {{.ID}})
```

{% endraw %}
