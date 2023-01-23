---
layout: post
title:  Google Sheetsでバイトサイズに単位を付ける
date:   2020/03/14 13:37:28 +0900
tags:   google
---

## 数字フォーマットで単位を付ける

Google SheetsでCustom number formatsに以下を入れることでバイトサイズに単位を付けることができる。

```text
[<1000000]0.00," KB";[<1000000000]0.00,," MB";0.00,,," GB"
```
