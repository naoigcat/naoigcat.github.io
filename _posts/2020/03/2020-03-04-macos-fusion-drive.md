---
layout: post
title:  macOSのFusion Driveを再構成する
date:   2020/03/04 11:21:44 +0900
tags:   macos
---

## 一部のmacOS端末で採用されていた

Fusion DriveはHDDとSSDを組み合わせたドライブで2012年から2019年に発売されたiMacやMac miniで採用されている。

## 再構成が必要になる場合がある

Fusion Driveを使用しているmacOSをクリーンインストールしようとしてインターネットリカバリからディスクユーティリティを起動するとAPPLE SSDとAPPLE HDDの2つのディスクが認識される場合がある。

Fusion Driveが解除されてしまっているため再度Fusion Driveを構成し直す必要がある。

## 必要に応じてFusion Driveを解除する

Fusion Driveが構成されている場合でも調子が悪い時は先に解除する。

1.  メニューバーのユーティリティからターミナルを起動する。
2.  下記コマンドを実行して既に`Logical Volume Group`の後にあるUUIDをコピーする。

    ```sh
    diskutil cs list
    ```

3.  下記コマンドの`****`にコピーしたUUIDを入れて実行する。

    ```sh
    diskutil cs delete ****
    ```

## Fusion Driveを再構成する

1.  ディスクユーティリティからAPPLE SSDとAPPLE HDDそれぞれの情報を確認して`BSD装置ノード`の値を確認する。通常はdisk0とdisk1になっている。
2.  メニューバーのユーティリティからターミナルを起動する。
3.  下記コマンドを実行する。`disk0`と`disk1`は1.で確認した値に置き換える。

    ```sh
    diskutil cs create "Macintosh HD" disk0 disk1
    ```

4.  下記コマンドを実行して既に`Logical Volume Group`の後にあるUUIDをコピーする。

    ```sh
    diskutil cs list
    ```

5.  下記コマンドの`****`にコピーしたUUIDを入れて実行する。

    ```sh
    diskutil cs createVolume **** jhfs+ "Macintosh HD" 100%
    ```

## Appleも修復方法を公開している

-   ref. [Fusion Drive が分割された場合の修復方法](https://support.apple.com/ja-jp/HT207584)
