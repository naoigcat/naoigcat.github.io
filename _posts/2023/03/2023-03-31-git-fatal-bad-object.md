---
title:     Gitで'bad object'エラーが発生する
date:      2023-03-31 12:10:02 +0900
tags:      git
---

## プルなどの操作を行ったときにエラーが発生する

Gitリポジトリでプルなどの操作を行ったときに`fatal: bad object`エラーが発生する場合がある。

```sh
$ git pull
fatal: bad object refs/heads/HEAD 2
error: https://github.com/xxx/xxx.git did not send all necessary objects
```

## エラーになったファイルを削除することで解消される

エラーメッセージにあるファイルが作成されたことが原因のため、そのファイルを削除するとエラーが解消される。

```sh
$ rm .git/refs/heads/HEAD\ 2
$ git pull
Already up to date.
```
