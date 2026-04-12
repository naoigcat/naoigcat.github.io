---
layout: post
title:  AIエージェントツールの利用状況を確認する
date:   2026-04-12 16:19:28 +0900
tags:   bash
---

## AIエージェントツールの利用状況を確認する

Claude Codeを始めとするAIエージェントツールの利用状況を確認するには、`ccusage` コマンドを使用する。

```bash
$ npx -y ccusage
 ╭──────────────────────────────────────────╮
 │                                          │
 │  Claude Code Token Usage Report - Daily  │
 │                                          │
 ╰──────────────────────────────────────────╯
```

Codex用のパッケージも公開されている。

```bash
$ npx -y @ccusage/codex
 ╭───────────────────────────────────────────────────────────╮
 │                                                           │
 │  Codex Token Usage Report - Daily (Timezone: Asia/Tokyo)  │
 │                                                           │
 ╰───────────────────────────────────────────────────────────╯
```
