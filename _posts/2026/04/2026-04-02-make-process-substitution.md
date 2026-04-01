---
layout: post
title:  Makeファイルでプロセス置換を使用する
date:   2026/04/02 07:01:44 +0900
tags:   make
---

## プロセス置換を使用してコマンドの出力をファイルのように扱う

`diff`コマンドなど、ファイルを引数に取るコマンドで、プロセス置換を使用してコマンドの出力をファイルのように扱うことができる。

```bash
diff <(command1) <(command2)
```

## Makefileでプロセス置換を使用する

Makefileでプロセス置換を使用する場合、シェルが`/bin/sh`であるため、Bashの機能であるプロセス置換が利用できない。

MakefileのシェルをBashに変更することで、プロセス置換を使用できるようになる。

```makefile
SHELL := /bin/bash

target:
    diff <(command1) <(command2) || echo "No differences"
```
