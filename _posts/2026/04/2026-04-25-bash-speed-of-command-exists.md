---
layout: post
title:  Bashでのコマンド存在確認の速度を比較する
date:   2026-04-25 08:58:30 +0900
tags:   bash
---

## コマンド存在確認の速度を比較する

Zshでは `hash` コマンドが最も早いが `which` コマンドも十分高速で `type` コマンド等と差がない。

```sh
$ TIMEFMT='%U user %S system %P cpu %*E total'
$ time zsh -c 'for (( i = 0 ; i < 100000 ; i++ )); do which ls; done >/dev/null'
0.25s user 0.70s system 99% cpu 0.955 total
$ time zsh -c 'for (( i = 0 ; i < 100000 ; i++ )); do hash ls; done >/dev/null'
0.05s user 0.02s system 97% cpu 0.073 total
$ time zsh -c 'for (( i = 0 ; i < 100000 ; i++ )); do hash -r; hash ls; done >/dev/null'
0.30s user 0.70s system 99% cpu 0.998 total
$ time zsh -c 'for (( i = 0 ; i < 100000 ; i++ )); do command -v ls; done >/dev/null'
0.27s user 0.73s system 99% cpu 1.005 total
$ time zsh -c 'for (( i = 0 ; i < 100000 ; i++ )); do hash -r; command -v ls; done >/dev/null'
0.33s user 0.74s system 99% cpu 1.081 total
$ time zsh -c 'for (( i = 0 ; i < 100000 ; i++ )); do command -V ls; done >/dev/null'
0.28s user 0.71s system 99% cpu 0.989 total
$ time zsh -c 'for (( i = 0 ; i < 100000 ; i++ )); do hash -r; command -V ls; done >/dev/null'
0.34s user 0.76s system 99% cpu 1.103 total
$ time zsh -c 'for (( i = 0 ; i < 100000 ; i++ )); do type ls; done >/dev/null'
0.26s user 0.71s system 99% cpu 0.979 total
$ time zsh -c 'for (( i = 0 ; i < 100000 ; i++ )); do type -a ls; done >/dev/null'
0.40s user 1.07s system 99% cpu 1.475 total
```

`Bash` では `which` コマンドが非常に遅く、 `hash` コマンドが最も早いが `command -v` コマンドや `type` コマンドと差がない。

```sh
$ TIMEFMT='%U user %S system %P cpu %*E total'
$ time bash -c 'for (( i = 0 ; i < 100000 ; i++ )); do which ls; done >/dev/null'
40.36s user 49.07s system 78% cpu 1:53.63 total
$ time bash -c 'for (( i = 0 ; i < 100000 ; i++ )); do hash ls; done >/dev/null'
0.51s user 1.13s system 99% cpu 1.641 total
$ time bash -c 'for (( i = 0 ; i < 100000 ; i++ )); do hash -r; hash ls; done >/dev/null'
0.58s user 1.11s system 99% cpu 1.704 total
$ time bash -c 'for (( i = 0 ; i < 100000 ; i++ )); do command -v ls; done >/dev/null'
0.52s user 0.90s system 99% cpu 1.419 total
$ time bash -c 'for (( i = 0 ; i < 100000 ; i++ )); do hash -r; command -v ls; done >/dev/null'
0.60s user 0.93s system 99% cpu 1.542 total
$ time bash -c 'for (( i = 0 ; i < 100000 ; i++ )); do command -V ls; done >/dev/null'
0.54s user 0.91s system 99% cpu 1.464 total
$ time bash -c 'for (( i = 0 ; i < 100000 ; i++ )); do hash -r; command -V ls; done >/dev/null'
0.61s user 0.93s system 97% cpu 1.573 total
$ time bash -c 'for (( i = 0 ; i < 100000 ; i++ )); do type ls; done >/dev/null'
0.50s user 0.91s system 99% cpu 1.426 total
$ time bash -c 'for (( i = 0 ; i < 100000 ; i++ )); do type -a ls; done >/dev/null'
0.70s user 1.08s system 99% cpu 1.793 total
```

## 確認対象ごとの速度を比較する

```sh
$ TIMEFMT='%U user %S system %P cpu %*E total'
$ time zsh -c 'for (( i = 0 ; i < 1000000 ; i++ )); do type -a cd; done >/dev/null'
4.65s user 12.26s system 99% cpu 16.937 total
$ time zsh -c 'for (( i = 0 ; i < 1000000 ; i++ )); do type -a if; done >/dev/null'
3.72s user 7.73s system 99% cpu 11.471 total
$ time zsh -c 'for (( i = 0 ; i < 1000000 ; i++ )); do type -a ls; done >/dev/null'
4.06s user 10.81s system 99% cpu 14.884 total
$ time zsh -c 'for (( i = 0 ; i < 1000000 ; i++ )); do fn(){ :; }; type -a fn; done >/dev/null'
4.13s user 7.88s system 99% cpu 12.036 total
$ time zsh -c 'for (( i = 0 ; i < 1000000 ; i++ )); do alias ll="ls -l"; type -a ll; done >/dev/null'
4.81s user 8.00s system 99% cpu 12.826 total
$ time zsh -c 'for (( i = 0 ; i < 1000000 ; i++ )); do type -a ll; done >/dev/null'
3.71s user 7.76s system 99% cpu 11.490 total
```
