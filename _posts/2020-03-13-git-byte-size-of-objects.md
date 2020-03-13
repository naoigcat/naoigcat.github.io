---
layout: post
title:  Gitリポジトリ内の大容量ファイルを特定する
date:   2020/03/13 12:08:35 +0900
tags:   git
---

Gitリポジトリに巨大なファイルをコミットするとクローンに時間がかかるようになる。

下記の手順で調査を行うことで巨大なファイルを特定できる。特定したファイルを履歴から抹消することでリポジトリのサイズを小さくすることができる。

## オブジェクトファイルをパッキングする

下記コマンドを実行して`packfile`を作成する。クローン直後であれば不要。

```bash
cd /path/to/repository
git gc
```

## オブジェクトファイルをサイズ順に表示する

下記コマンドを実行するとサイズが大きい順に100件表示する。

```bash
git verify-pack -v .git/objects/pack/pack-*.idx |
grep blob |
sort -k3nr |
head -n 100 |
ruby -ane "IO.popen(%Q{git rev-list --all --objects | grep #{\$F[0]}}, &:read).chomp.split.tap {|path| puts [\$F[0],path[1..-1]&.join,\$F[2],\$F[3]].join(%Q{\t}) }"
```

`git verify-pack`は`packfile`内のオブジェクトの情報を表示するコマンドで下記のフォーマットで出力する。

```output
SHA-1 type size size-in-packfile offset-in-packfile
```

`git rev-list`でオブジェクトのパスとハッシュの一覧を出力できるため1列目の情報からパスを取得し、3列目と4列目のサイズ情報を表示することでサイズの大きいファイルを特定できる。
