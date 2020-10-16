---
layout: post
title:  grepコマンドの再帰検索で複数のディレクトリを除外する
date:   2020/03/07 15:26:31 +0900
tags:   sh
---

grepコマンドで検索する時に除外したいディレクトリがある場合は`--exclude-dir`で指定できる。

複数のディレクトリを指定する場合は`{}`の中にカンマ区切りで入れる。`bash`のブレース展開は適用されない。

```sh
grep -R word ./ --exclude-dir={bin,exe}
```