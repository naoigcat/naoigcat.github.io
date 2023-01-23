---
layout: post
title:  スクリーンショットのファイル名を自動的に変更する
date:   2017/09/03 18:53:00 +0900
tags:   macos
---

## スクリーンショットは接頭辞しか変えられない

macOSで保存したスクリーンショットはファイル名が`接頭辞 + スペース + 日付`となっており、フォーマットを自由に変更できない。

## ファイルを監視してリネームする

下記の方法で保存された段階でリネームされるようにして自由な形式の名前にできる。

1.  ファイルを開くとiCloud DriveのPreviewにリンクが作成されるので最初から保存先をiCloud Drive上に変更しておく。

    ```sh
    defaults write com.apple.screencapture location ~/Library/Mobile\ Documents/com~apple~Preview/Documents/
    killall SystemUIServer
    ```

2.  スクリーンショットが保存されるときに付く接頭辞を削除する。接頭辞とタイムスタンプの間のスペースは削除できないことに注意。

    ```sh
    defaults write com.apple.screencapture name ''
    killall SystemUIServer
    ```

3.  ツールをインストールする。

    ```sh
    brew install rename fswatch
    ```

4.  `fswatch`を利用してスクリーンショットの出力先フォルダを監視し、`rename`で名前を変更する。

    ```sh
    nohup /usr/local/bin/fswatch -0 -e '/\.' ~/Library/Mobile\ Documents/com~apple~Preview/Documents/ 2>/dev/null |
    xargs -0 -n1 /usr/local/bin/rename 's/ (\d+)-(\d+)-(\d+) (\d+)\.(\d+)\./$1$2$3T$4$5/g' 2>/dev/null 1>&2 &
    ```
