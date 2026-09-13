---
title:     SQLiteでUPSERTを実行する
date:      2023-03-07 12:10:19 +0900
tags:      sqlite
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
-- 1|manager|2023-03-07 03:11:00
-- 2|developer|2023-03-07 03:11:00
```

## 主キーが重複する場合は更新する

`ON CONFLICT`を使用すると主キーが重複する場合にデータを挿入ではなく更新できる。 `DO UPDATE` では競合ターゲット（ここでは `id`）を明示するのが分かりやすい。 SQLite 3.35.0 以降は最後の `ON CONFLICT` 句でターゲットを省略できるが、 PostgreSQL 互換や複数 UNIQUE 制約がある場合のため、対象列を書いておくとよい。新しい行の値は `excluded.列名` で参照できる。

```sql
CREATE TABLE users (id INTEGER, name TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(id));
INSERT INTO users (id, name) VALUES (1, 'administrator');
SELECT * FROM users;
-- 1|administrator|2023-03-07 03:10:00
INSERT INTO users (id, name) VALUES (2, 'developer') ON CONFLICT(id) DO UPDATE SET name = 'DEVELOPER';
INSERT INTO users (id, name) VALUES (1, 'manager') ON CONFLICT(id) DO UPDATE SET name = excluded.name;
SELECT * FROM users;
-- 1|manager|2023-03-07 03:10:00
-- 2|developer|2023-03-07 03:11:00
```
