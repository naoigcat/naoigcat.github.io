---
layout: post
title:  新バージョンのXcodeで使えるようになったOSバージョンを旧バージョンのXcodeで使用する
date:   2023/01/10 13:17:48 +0900
tags:   xcode
---

## 新しいOSバージョンを旧バージョンのXcodeで使用したい背景

Xcodeはバージョン毎にデバッグ実行可能な最大OSバージョンが決まっており、新しいOSバージョンが出たときにはXcode自体もアップデートする必要がある。

Xcodeのバージョンが変わると破壊的な変更が行われていたり、コードを変更しないとビルドできなかったりする。

一方、配布用の証明書でアーカイブしたバイナリは新しいOSバージョンの端末にもインストールすることができる。

そのため旧バージョンのXcodeを使いながら新しいOSバージョンの実機やシミュレーターで動作確認を行いたい。

## 新しいOSバージョン向けにデバッグ実行可能にする方法

1.  新バージョンのXcodeをダウンロードする。

    -   cf. [xcodes](https://github.com/RobotsAndPencils/xcodes)

1.  下記のディレクトリをコピーする。

    ```sh
    /Applications/Xcode-X.Y.Z.app/Contents/Developer/Platforms/iPhoneOS.platform/DeviceSupport/A.B
    ```

    -   `Xcode-X.Y.Z.app`は新バージョンのXcode
    -   `A.B`はデバッグ実行したいOSバージョン

1.  下記のディレクトリにペーストする。

    ```sh
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/DeviceSupport
    ```

上記手順で新しいOSバージョンの実機もしくはシミュレーターでデバッグ実行できるようになる。

## 新しい機種のシミュレーターを起動する方法

1.  新バージョンのXcodeを起動する。

1.  新しい機種のシミュレーターを追加して起動する。

1.  新バージョンのXcodeを終了し、旧バージョンのXcodeを起動する。

1.  シミュレーターを終了させていた場合は起動させる。

    ```sh
    open /Applications/Xcode-X.Y.Z.app/Contents/Developer/Applications/iOS\ Simulator.app
    ```

    -   `Xcode-X.Y.Z.app`は新バージョンのXcode

上記手順で新しい機種のシミュレーターでデバッグ実行できるようになる。
