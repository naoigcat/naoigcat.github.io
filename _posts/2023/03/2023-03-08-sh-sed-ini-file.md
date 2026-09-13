---
title:     設定ファイルから情報を抽出する
date:      2023-03-08 12:13:02 +0900
tags:      bash
---

## INIファイルから特定のセクションを抽出する

`sed`コマンドの機能を使用してINIファイルから特定のセクションの内容を抽出することができる。拡張正規表現は `-E`（BSD / GNU 共通）を使う。文字クラス内のタブは ANSI-C クォートの `\t` で渡す（`\\t` だとバックスラッシュと `t` の2文字になってしまい、タブにマッチしない）。

```sh
$ curl -fsL https://raw.githubusercontent.com/php/php-src/master/php.ini-development |
  sed -nEe "$(echo $'/^[ \t]*\\[ldap\\][ \t]*$/{p\n:loop\nn\n/^[ \t]*\\[[^]]+\\][ \t]*$/q\np\nb loop\n}')"
[ldap]
; Sets the maximum number of open links or -1 for unlimited.
ldap.max_links = -1
```

## AWSの設定ファイルから環境変数を生成する

AWSのコマンドライン設定ファイル (`~/.aws/config`, `~/.aws/credentials`) はINIファイルの形式のため特定のプロファイルの情報から環境変数を設定するコマンドを生成することができる。

```sh
$ cat <<CONFIG > ~/.aws/config
[default]
region = ap-northeast-1
CONFIG
$ cat <<CREDENTIALS > ~/.aws/credentials
[default]
aws_access_key_id = ...
aws_secret_access_key = ...
CREDENTIALS
$ (
    sed -nEe "$(echo $'/^[ \t]*\\[default\\][ \t]*$/{:loop\nn\n/^[ \t]*\\[[^]]+\\][ \t]*$/q\n/./p\nb loop\n}')" ~/.aws/config
    sed -nEe "$(echo $'/^[ \t]*\\[default\\][ \t]*$/{:loop\nn\n/^[ \t]*\\[[^]]+\\][ \t]*$/q\n/./p\nb loop\n}')" ~/.aws/credentials
  ) | awk '{print "export "toupper($1)$2$3}' | sed -e 's/REGION/AWS_REGION/'
export AWS_REGION=ap-northeast-1
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
```
