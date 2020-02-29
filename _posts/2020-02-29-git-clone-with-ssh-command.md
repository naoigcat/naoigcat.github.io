---
layout: post
title:  Gitでクローンする時に秘密鍵を指定する
date:   2020/02/29 15:26:37 +0900
tags:   git
---

Gitでクローンする際に秘密鍵を指定したい場合`-c`オプションで一時的に`sshcommand`を指定する。

```sh
git -c core.sshcommand='ssh -i ~/.ssh/id_rsa -F /dev/null' clone git@github.com:example/example.git
```

この状態だと次以降のGitコマンドで指定した秘密鍵が使用されないためリポジトリに設定しておく。

```sh
cd example
git config --local core.sshcommand 'ssh -i ~/.ssh/id_rsa -F /dev/null'
```
