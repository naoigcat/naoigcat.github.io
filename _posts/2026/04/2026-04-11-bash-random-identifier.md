---
layout: post
title:  ランダムな識別子を生成する
date:   2026/04/11 02:17:18 +0900
tags:   bash
---

## UUIDを生成する

macOSにはデフォルトで `uuidgen` コマンドがインストールされており、RFC 4122に準拠したUUIDを手軽に生成できる。

```bash
$ uuidgen
ECA02A6F-C2AE-4366-B1C6-BB3099908F00
```

Linuxに `uuid-runtime` をインストールすると `uuidgen` コマンドが利用できるようになる。macOSと違って小文字で出力される。

```bash
$ docker run -i debian:bookworm bash -c 'apt-get update >/dev/null 2>&1 ; apt-get install -y uuid-runtime >/dev/null 2>&1 ; uuidgen'
83d5d3e0-f264-4043-a433-dcd2a6126124
```

Linuxでは仮想ファイルシステム `/proc` を利用してカーネルが生成したUUIDを取得できる。

```bash
$ docker run -i debian:bookworm cat /proc/sys/kernel/random/uuid
318a89cc-273d-4f95-91a0-cef9f7e4225e
```

## 128ビット文字列を生成する

Linuxの `util-linux` パッケージに含まれる `mcookie` コマンドを使うと、128ビットの完全なランダム16進数文字列を出力できる。ハイフンを挿入しても規格仕様を満たしていないためUUIDとしては使用できない。

```bash
$ docker run -i debian:bookworm mcookie                         
7b78a2818a6d28188014b20ac1964b8c
```

OpenSSLがインストールされている環境であれば、`rand` サブコマンドを使って128ビット（16バイト）のランダムな16進数文字列を簡単に生成できる。環境に依存しづらく、さまざまなOSで利用しやすい。

```bash
$ openssl rand -hex 16
14b8a2e2a046f40c7cfd8b4cdb8ea49d
```

特殊ファイルである乱数デバイス `/dev/urandom` から16バイトを読み込み、macOSなどで標準的に利用できる `xxd` のようなコマンドを利用して16進数文字列に変換することもできる。

```bash
$ head -c 16 /dev/urandom | xxd -p
c1f54e19875f2b8429ef19fe48bc1013
```
