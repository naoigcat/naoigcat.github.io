---
layout: post
title:  Rubyでデフォルト以外のGemをアンインストールする
date:   2017/09/08 07:45:00 +0900
tags:   ruby
---

## コマンドでGemをアンインストールする

グローバル環境にGemをインストールしていて不要なGemをアンインストールする必要が出てきたとき、
もしくは環境構築用のスクリプトを作成するときに下記のスクリプトを実行することでデフォルト以外のGemをアンインストールできる。

### Ruby >= 2.4

```sh
gem list | grep -v "default" | cut -d " " -f 1 | xargs gem uninstall -aIx
gem install bundler --no-document
```

### Ruby < 2.4

```sh
gem list --detail | perl -pe 's/\n/\t/g' | perl -pe 's/\t+   //g' | perl -pe 's/\t/\n/g' | grep -v 'default\|^\s*$' | cut -d " " -f 1 | xargs gem uninstall -aIx
gem install bundler --no-document
```
