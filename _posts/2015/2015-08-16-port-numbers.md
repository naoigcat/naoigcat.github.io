---
layout: post
title:  サービスに使用されていないポート一覧を取得する
date:   2015-08-16 10:47:00 +0900
tags:   sh
---

IANAが公開しているサービス別の利用ポート一覧からIANAに登録されているサービスが使用していないポート一覧を生成する。

```sh
curl -f#L https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.csv |
awk -F',' '/([0-9]{4}-[0-9]{4}|[0-9]{5}-[0-9]{5}),,Unassigned/{print $2}' |
awk -F'-' '$2-$1>20{print $1,$2-$1}' |
sort -k 2,2 -n -r
```
