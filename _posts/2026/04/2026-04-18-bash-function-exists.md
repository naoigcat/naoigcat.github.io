---
layout: post
title:  Bashのシェル関数の定義を読む
date:   2026-04-18 20:03:47 +0900
tags:   bash
---

## 関数が定義されているかを調べる

`which`コマンドを関数に対して実行すると`zsh`でのみ関数の定義を返す。

```sh
$ zsh -c 'f() { echo foo; }; which f'
f () {
        echo foo
}
$ bash -c 'f() { echo foo; }; which f' || echo 'not found'
not found
$ ksh -c 'f() { echo foo; }; which f' || echo 'not found'
not found
```

`bash`では`declare -f`、`ksh`では`typeset -f`を使用して関数の定義を表示できる。

```sh
$ bash -c 'f() { echo foo; }; declare -f f'
f ()
{
    echo foo
}
$ ksh -c 'f() { echo foo; }; typeset -f f'
f() { echo foo; };
```
