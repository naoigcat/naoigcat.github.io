---
layout: post
title:  PHPStormでDocker+XDebugを使用する
date:   2020/12/29 16:08:49 +0900
tags:   phpstorm docker
---

PHPStormのXDebug設定はプロジェクト毎に保存されるため書くプロジェクトで設定が必要。

## Preferences | Build, Execution, Deployment | Docker

下記は全プロジェクト共通のため一度だけ設定する。

1.  `+`ボタンをクリックして、Docker実行環境を追加する
2.  `Connect to Docker daemon with:`は`Docker for Mac`を選択する

## Preferences | Languages & Frameworks | PHP

1.  `PHP language level`で使用しているPHPのバージョンを指定する
2.  `CLI Interpreter`の`...`をクリックする
    1.  `+`ボタンをクリックしてから`From Docker, Vagrant, VM, WSL, Remote...`をクリックする
    2.  `Docker Compose`を選択する
    3.  `Service:`からPHP-FPMが実行されているサービスを選択する
    4.  `OK`をクリックする
    5.  `Lifecycle`の`Connect to existing container`を選択する
    6.  `OK`をクリックする
3.  `PHP Runtime`タブを選択する
4.  `Sync Extensions with Interpreter`をクリックする
5.  `Apply`をクリックする

## Preferences | Languages & Frameworks | PHP | Debug

1.  `Debug port`をPHP-FPMの設定で指定したポート番号に合わせる
2.  `Ignore external connections through unregistered server configurations`をチェックする
    -   外部からのデバッグ接続がサーバー構成に未登録の構成なら無視する
3.  `Break at first lien in PHP scripts`をチェックする（設定に問題ないことが確認できてらチェックを外す）

## Preferences | Languages & Frameworks | PHP | Servers

1.  `+`ボタンをクリックする
2.  `Name`に好きな名前を入れる
3.  `Host`と`Port`はこのプロジェクトで起動したページにアクセスする時のホスト名とポート番号を入れる
4.  `Use path mappings`にチェックを入れ、Dockerコンテナにマウントされるローカルディレクトリの`Absolute path on the server`にマウント先のパスを入れる
5.  `Apply`をクリックする

## Configuration

1.  右上`Add Configuration...`をクリックする
2.  `+`ボタンをクリックしてから`PHP Remote Debug`を選択する
3.  `Name`に好きな名前を入れる
4.  `OK`をクリックする
