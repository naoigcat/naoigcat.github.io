---
layout: post
title:  Docker Hubからイメージのタグ一覧を取得する
date:   2023/03/28 12:17:50 +0900
tags:   docker
---

## イメージのタグ一覧を取得する

Docker HubにはAPIが用意されていて

```url
https://registry.hub.docker.com/v2/repositories/{USER}/{IMAGE}/tags
```

の形式のURLにGETリクエストを送ると利用可能なタグ一覧がJSON形式で返ってくる。

```sh
$ export REPOSITORIES=https://registry.hub.docker.com/v2/repositories
$ curl -s $REPOSITORIES/library/alpine/tags | jq -r '.results[].name'
latest
edge
3.17.2
3.17
3.16.4
3.16
3.15.7
3.15
3.14.9
3.14
```

公式イメージの場合`{USER}`は`library`になる。
