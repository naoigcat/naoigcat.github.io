---
layout: post
title:  同一ハッシュ値となる文字列が発見されている
date:   2024/03/20 23:00:36 +0900
tags:   sh
---

## 暗号学的ハッシュ関数には要求される性質がある

[MD5](https://ja.wikipedia.org/wiki/MD5)は1991年に開発された暗号学的ハッシュ関数でハッシュ値は128ビットである。

暗号学的ハッシュ関数には次のような暗号学的な性質が要求される。

-   ハッシュ値からそのようなハッシュ値となるメッセージを求めることが（事実上）不可能であること（弱衝突耐性）。
-   同じハッシュ値となる異なるメッセージのペアを求めることが（事実上）不可能であること（強衝突耐性）。
-   メッセージの一部を変えたときハッシュ値が大幅に変わって元のメッセージのハッシュ値とは相関がないように見えること。

これらの性質によりメッセージの内容を保証するダイジェストとして利用することができる。

## 同一ハッシュ値の非ユニークなデータ列を生成できる

MD5は同一ハッシュ値の非ユニークなデータ列を生成できる実装が広まっており、強衝突耐性は容易に突破されうる脆弱性がある。

ただし、任意に与えられたハッシュ値に対してそのハッシュ値となるデータ列を生成できる実装が広まっておらず、弱衝突耐性が容易に突破されうるわけではないため、無改竄性を証明することは可能である。

## 同一ハッシュ値となる文字列が発見されている

<https://x.com/realhashbreaker/status/1770161965006008570>

```sh
$ a=TEXTCOLLBYfGiJUETHQ4hAcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak
$ b=TEXTCOLLBYfGiJUETHQ4hEcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak
$ test $a = $b && echo '$a == $b' || echo '$a != $b'
$a != $b
$ test $(md5 -s $a | awk '{print $4}') = $(md5 -s $b | awk '{print $4}') && echo 'md5($a) == md5($b)' || echo 'md5($a) != md5($b)'
md5($a) == md5($b)
```
