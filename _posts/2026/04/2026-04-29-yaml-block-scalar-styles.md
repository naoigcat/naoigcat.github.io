---
title:     YAMLで複数行の値を表現する
date:      2026-04-29 12:34:38 +0900
tags:      yaml
---

## ブロックスカラーを使用する

YAML 1.2.2の仕様書の[8.1. Block Scalar Styles](https://yaml.org/spec/1.2.2/#81-block-scalar-styles)に複数行のスカラーを表すブロックスカラーのスタイルが定義されている。

リテラルスタイル (`|`) では改行がそのまま改行として扱われる。

```sh
$ ruby -ryaml -e 'puts YAML.safe_load($stdin.read)["literal"]' <<'YAML'
literal: |
  This is a literal block scalar.
  Newlines are preserved.

  Blank lines are preserved as newlines.
YAML
This is a literal block scalar.
Newlines are preserved.

Blank lines are preserved as newlines.
```

折り畳みスタイル (`>`) では行の折り畳み (`line folding`) の規則に従い、改行が空白1文字に畳まれる。ただし、空行に続く改行やより深くインデントされた行まわりの改行は段落単位で解釈される。

```sh
$ ruby -ryaml -e 'puts YAML.safe_load($stdin.read)["folded"]' <<'YAML'
folded: >
  This is a folded block scalar.
  Newlines are folded into spaces, except for
  blank lines and more indented lines.

  Blank lines are preserved as newlines.
    Indented lines are preserved as newlines.
YAML

This is a folded block scalar. Newlines are folded into spaces, except for blank lines and more indented lines.
Blank lines are preserved as newlines.
  Indented lines are preserved as newlines.
```

## ブロックスカラーのヘッダーに指示子を付ける

ブロックスカラーのスタイルを選ぶための記号（`|` / `>`）のあとに、**ヘッダ**と呼ばれる指示子を付けることができる。ヘッダは、スカラー内容のインデントレベルや末尾改行・末尾空行の扱いを指定するためのものである。

インデント指示子 (`1` ~ `9`) は、内容行の先頭から何スペースを剥がすかを指定するものである。省略した場合は、最初の非空行の先頭スペース数などから自動的に検出される。

```sh
$ ruby -ryaml -e 'puts YAML.safe_load($stdin.read)["literal"]' <<'YAML'
literal: |1
    This is a literal block scalar.
    Newlines are preserved.

    Blank lines are preserved as newlines.
YAML
   This is a literal block scalar.
   Newlines are preserved.

   Blank lines are preserved as newlines.
```

トリミング指示子 (`-`, `+`) は、スカラー内容の末尾改行や末尾空行の扱いを指定するものである。`-` は最終改行と末尾の空行を内容から除外し、`+` は最終改行と末尾の空行を内容に含める。省略した場合は、最終改行は内容に残すが、末尾の空行は除外する。

```sh
$ ruby -ryaml -e 'puts YAML.safe_load($stdin.read)
  .inspect
  .gsub(/\A\{/, "{\n ")
  .gsub(/, /, ",\n ")
  .sub(/\}\z/, "\n}")' <<'YAML'
folded1: >
  This is a folded block scalar.

folded2: >-
  This is a folded block scalar.

folded3: >+
  This is a folded block scalar.

YAML
```

```ruby
{
 "folded1"=>"This is a folded block scalar.\n",
 "folded2"=>"This is a folded block scalar.",
 "folded3"=>"This is a folded block scalar.\n\n"
}
```
