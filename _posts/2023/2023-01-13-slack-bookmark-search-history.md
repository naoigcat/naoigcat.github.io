---
layout: post
title:  Slackの検索履歴をブックマークする
date:   2023/01/13 12:05:19 +0900
tags:   slack
---

## 目的

Slackでは履歴から過去に検索した文言で再検索が行えるがピン留め等は行えず、ほかの人に共有することもできない。

リンクにしてチャンネルのブックマークに追加できれば便利になる。

## 方法

1.  ブラウザでSlackを開く
1.  デスクトップアプリへのリダイレクトをキャンセルし、`use Slack in your browser`をクリックする
1.  検索バーから検索を実行する
1.  アドレスバーからURLをコピーする
1.  ドメインの`app`をワークスペースの識別子に変更し、`/client/XXXXXXXXXXX`の部分を削除する

    ```diff
    - https://app.slack.com/client/XXXXXXXXXXX/search/search-eyxxxx
    + https://workspace.slack.com/search/search-eyxxxx
    ```

1.  デスクトップアプリでリンクを開く
