---
layout: post
title:  Dockerコンテナ内に標準入力をパイプで渡す
date:   2023/02/06 12:09:42 +0900
tags:   sh docker
---

## コンテナを起動する

```sh
docker run --rm --name example -itd alpine
```

## オプションなしだと出力なしで終了する

`docker exec`にオプションを渡さないとコンテナ外の標準入力は無視される。

```sh
$ docker exec example cat - /etc/hostname
> 10ebf333b3ac
$ echo hello | docker exec example cat - /etc/hostname
> 10ebf333b3ac
```

## オプションを指定して標準入力を引き継げる

`docker exec`に`--interactive`オプションを渡すと標準入力をコンテナ内のコマンドに引き継げる。

```sh
$ docker exec -i example cat - /etc/hostname
< test
> test
< ^C # => 入力待ちになるため中断するにはSIGINTを送信する必要あり
$ echo hello | docker exec -i example cat - /etc/hostname
> hello
> 10ebf333b3ac
```

## 疑似端末を使用すると入力を待ち続ける

`docker exec`に`--tty`オプションを渡すと疑似端末側の入力を待ち続けるため処理が終了しない。

```sh
$ docker exec -t example cat - /etc/hostname
< ^C # => 入力待ちになるため中断するにはSIGINTを送信する必要あり
$ echo hello | docker exec -t example cat - /etc/hostname
< ^C # => 入力待ちになるため中断するにはSIGINTを送信する必要あり
```

## 両方のオプションを渡すと端末が一致しないエラーになる

`docker exec`に`--interactive`と`--tty`両方のオプションを渡すとコンテナ外の入力端末と疑似端末が異なるためコンテナ外から標準入力を引き継ぐことができない。

```sh
$ docker exec -it example cat - /etc/hostname
< test
> test
< ^C # => 入力待ちになるため中断するにはSIGINTを送信する必要あり
$ echo hello | docker exec -it example cat - /etc/hostname
> the input device is not a TTY
```
