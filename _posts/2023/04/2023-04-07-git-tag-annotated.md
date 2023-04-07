---
layout: post
title:  Gitのタグに注釈を付ける
date:   2023/04/07 12:14:33 +0900
tags:   git
---

## Gitのタグには3種類ある

Gitで使用できるタグには以下の3種類ある。

1.  軽量版のタグ
1.  注釈付きのタグ
1.  署名付きのタグ

### 軽量版のタグ

軽量版のタグは下記コマンドで付けることのできる一番情報が軽量なタグで、特定のコミットに対する別名を付けるために利用する。

```sh
$ git tag {TAG_NAME}
$ tig show {TAG_NAME}
commit ac5c889d66ef1c53a1a98862caf1a6b7702ced56 (HEAD -> master, tag: {TAG_NAME}, origin/master, origin/HEAD)
Author: naoigcat <17925623+naoigcat@users.noreply.github.com>
Date:   Thu Apr 6 12:11:46 2023 +0900

    ...
```

### 注釈付きのタグ

注釈付きのタグは`-a`オプションを指定することで付けることのできるタグで、作成者、作成日、作成メッセージなどの追加情報を付与できる。

```sh
$ git tag -a {TAG_NAME} -m "annotated tag"
$ git show {TAG_NAME}
tag {TAG_NAME}
Tagger: naoigcat <17925623+naoigcat@users.noreply.github.com>
Date:   Fri Apr 7 12:14:33 2023 +0900

annotated tag

commit ac5c889d66ef1c53a1a98862caf1a6b7702ced56 (HEAD -> master, tag: {TAG_NAME}, origin/master, origin/HEAD)
Author: naoigcat <17925623+naoigcat@users.noreply.github.com>
Date:   Thu Apr 6 12:11:46 2023 +0900

    ...
```

### 署名付きのタグ

署名付きのタグは`-s`オプションを指定することで付けることのできるタグで、注釈付きのタグの情報に加えてGPGキーによる署名を付与できる。

署名を確認することで`Tagger`に指定されたユーザーが本当にタグの作成を行ったかどうかの確認が行える。

```sh
$ git tag -s {TAG_NAME} -m "signed tag"
$ git show {TAG_NAME}
tag {TAG_NAME}
Tagger: naoigcat <17925623+naoigcat@users.noreply.github.com>
Date:   Fri Apr 7 12:14:33 2023 +0900

signed tag
-----BEGIN PGP SIGNATURE-----
...
-----END PGP SIGNATURE-----
commit ac5c889d66ef1c53a1a98862caf1a6b7702ced56 (HEAD -> master, tag: {TAG_NAME}, origin/master, origin/HEAD)
Author: naoigcat <17925623+naoigcat@users.noreply.github.com>
Date:   Thu Apr 6 12:11:46 2023 +0900

    ...
```
