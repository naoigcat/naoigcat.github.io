---
layout: post
title:  Amazon Athenaで予約キーワードをエスケープする
date:   2023/01/24 12:20:51 +0900
tags:   amazon sql
---

## クエリに予約キーワードを含む場合はエスケープする

Amazon Athenaで[予約キーワード](https://docs.aws.amazon.com/ja_jp/athena/latest/ug/reserved-words.html)を含むクエリを実行するときは予約キーワードをエスケープする必要がある。

## DDLではバックティックを使用する

`DDL`ステートメントで予約キーワードをエスケープするにはバックティック`` ` ``で囲む。

```sql
CREATE EXTERNAL TABLE `partition` (
    `id` INT,
    `date` DATE
)
PARTITION BY (`year` STRING)
LOCATION 's3://bucket/';
```

## SELECTではダブルクォーテーションを使用する

`SELECT`ステートメントで予約キーワードをエスケープするにはダブルクォーテーション`"`で囲む。

```sql
SELECT "id"
FROM "partition"
WHERE "date" = '2023-01-24';
```
