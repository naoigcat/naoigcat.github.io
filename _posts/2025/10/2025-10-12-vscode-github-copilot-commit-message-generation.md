---
layout: post
title:  VSCodeのGitHub Copilotでコミットメッセージを生成する
date:   2025/10/12 20:10:46 +0900
tags:   vscode github-copilot
---

## VSCodeのGitHub Copilotでコミットメッセージを生成する

VSCodeで拡張機能GitHub Copilotをインストールしている場合、コミットメッセージを自動生成することができる。

Gitのコミットメッセージ入力欄の右側あるGenerate Commit Messageをクリックすることで生成できる。

-   Preferences: Open Keyboard Shortcuts (JSON)で下記のように設定することでショートカットキーで生成できる。

    ```json
    {
        "key": "ctrl+enter",
        "command": "github.copilot.git.generateCommitMessage"
    }
    ```

## コミットメッセージ生成時のプロンプトを指定できる

VSCodeの設定ファイルに下記の項目を追加することで、コミットメッセージ生成時のプロンプトを指定できる。

```json
{
    "github.copilot.chat.commitMessageGeneration.instructions": [
        {
            "text": "コミットメッセージは日本語の現在形で書くこと。"
        },
        {
            "text": "コミットメッセージは Conventional Commits に従うこと。"
        }
    ]
}
```
