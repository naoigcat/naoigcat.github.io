---
title:     grepコマンドの再帰検索で複数のディレクトリを除外する
date:      2020-03-07 15:26:31 +0900
tags:      bash
---

## オプションで検索対象から除外できる

grepコマンドで検索する時に除外したいディレクトリがある場合は`--exclude-dir`で指定できる。

複数のディレクトリを指定する場合は、`bash`のブレース展開で`--exclude-dir`を複数回渡す。

```sh
grep -R word . --exclude-dir={bin,exe}
# 展開後: grep -R word . --exclude-dir=bin --exclude-dir=exe
```
