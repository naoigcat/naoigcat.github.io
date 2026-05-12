---
layout:    post
title:     エージェントのスキルを管理する
date:      2026-04-30 06:56:16 +0900
tags:      agent
---

## エージェントのスキルを管理する

`npx skills` コマンドを使用して、エージェントのスキルを管理できる。

```sh
npx skills add vercel-labs/skills --skill find-skills --agent codex
```

## ロックファイルで管理する

スキルは `skills-lock.json` ファイルで管理される。インストールしたスキルはこのファイルに記録され、エージェントが使用するスキルのバージョンを固定することができる。

```json
{
  "skills": [
    {
      "name": "find-skills",
      "remote": "vercel-labs/skills",
      "version": "latest"
    }
  ]
}
```

```sh
# スキルを検索する
npx skills find <キーワード>

# インストール済みスキルを一覧する
npx skills list

# スキルをインストールする
npx skills add vercel-labs/skills --skill find-skills --agent codex

# スキルを更新する（特定名だけなら npx skills update <スキル名>）
npx skills update

# ロックファイルからスキルをインストールする
npx skills experimental_install

# スキルを削除する
npx skills remove find-skills && rm skills-lock.json && npx skills update
```
