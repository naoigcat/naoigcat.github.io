---
layout: post
title:  Dockerでnetwork not foundのエラーを解消する
date:   2023/03/23 12:40:47 +0900
tags:   docker
---

## コンテナの残骸が残っているエラーになる

コンテナを起動しようとすると`network not found`のエラーが発生するときがある。

```sh
$ docker compose up
[+] Running 2/0
 ⠿ Container app-1     Created                                              0.0s
 ⠿ Container db-1      Created                                              1.2s
Error response from daemon: network 0000000000000000000000000000000000000000000000000000000000000000 not found
```

これはコンテナが参照しているネットワークのみ削除されている時に発生するため強制的にコンテナを再作成することで解消できる。

```sh
$ docker compose up --force-recreate
[+] Running 2/0
 ⠿ Container app-1     Recreated                                            0.0s
 ⠿ Container db-1      Recreated                                            1.2s
Attaching to app-1, db-1
```

再作成しても解消されない場合は`compose.yaml`に以前は記述していたコンテナが残っている場合があるため明示的にそのコンテナを削除する。

```sh
$ docker container rm 000000000000
000000000000
```
