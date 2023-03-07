---
layout: post
title:  SQLiteでUPSERTを実行する
date:   2023/03/07 12:10:19 +0900
tags:   sqlite
---

## 主キーが重複する場合はデータを置き換える

`REPLACE INTO`を使用すると主キーが重複する場合にデータを置き換えられる。一度`DELETE`した後に`INSERT`されるため指定しなかった列もリセットされる。

```sql
CREATE TABLE users (id INTEGER, name TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(id));
INSERT INTO users (id, name) VALUES (1, 'administrator');
SELECT * FROM users;
-- 1|administrator|2023-03-07 03:10:00
REPLACE INTO users (id, name) VALUES (2, 'developer');
REPLACE INTO users (id, name) VALUES (1, 'manager');
SELECT * FROM users;
-- 2|developer|2023-03-07 03:11:00
-- 1|manager|2023-03-07 03:11:00
```

## 主キーが重複する場合は更新する

`ON CONFLICT`を使用すると主キーが重複する場合にデータを挿入ではなく更新できる。

```sql
CREATE TABLE users (id INTEGER, name TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(id));
INSERT INTO users (id, name) VALUES (1, 'administrator');
SELECT * FROM users;
-- 1|administrator|2023-03-07 03:10:00
INSERT INTO users (id, name) VALUES (2, 'developer') ON CONFLICT DO UPDATE SET name = 'DEVELOPER';
INSERT INTO users (id, name) VALUES (1, 'manager') ON CONFLICT DO UPDATE SET name = 'MANAGER';
SELECT * FROM users;
-- 1|MANAGER|2023-03-07 03:10:00
-- 2|developer|2023-03-07 03:11:00
```
