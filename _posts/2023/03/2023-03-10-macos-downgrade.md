---
layout: post
title:  macOSの古いバージョンをインストールする
date:   2023/03/10 12:01:10 +0900
tags:   macos
---

## [初期搭載されていたバージョンを再インストールする](https://support.apple.com/ja-jp/HT204904)

Intel搭載のMacでは、起動時に`shift + option + command + R`キーを押下しているとmacOS復旧画面が起動し、Macに当初搭載されていたmacOSか、それに一番近い現在も提供されているバージョンが再インストールできる。

上記を`option + command + R`キーで行うとそのMacと互換性のある最新のmacOSがインストールされる。

## [古いバージョンをダウンロードする](https://support.apple.com/ja-jp/HT211683)

macOS 10.13 High Sierra以降はAppleの[サポートページ](https://support.apple.com/ja-jp/102662)のリンクからApp Storeを開き、インストールすることができる。

-   [Sequoia 15](macappstores://apps.apple.com/app/macos-sequoia/id6596773750?mt=12)
-   [Sonoma 14](macappstores://apps.apple.com/app/macos-sonoma/id6450717509?mt=12)
-   [Ventura 13](macappstores://apps.apple.com/jp/app/macos-ventura/id1638787999?mt=12)
-   [Monterey 12](macappstores://apps.apple.com/jp/app/macos-monterey/id1576738294?mt=12)
-   [Big Sur 11](macappstores://apps.apple.com/jp/app/macos-big-sur/id1526878132?mt=12)
-   [Catalina 10.15](macappstores://apps.apple.com/jp/app/macos-catalina/id1466841314?mt=12)
-   [Mojave 10.14](macappstores://apps.apple.com/jp/app/macos-mojave/id1398502828?mt=12)
-   [High Sierra 10.13](macappstores://apps.apple.com/jp/app/macos-high-sierra/id1246284741?mt=12)

macOS 10.12 Sierra以前はAppleの[サポートページ](https://support.apple.com/ja-jp/102662)からディスクイメージをダウンロードする。.dmgファイルをマウントして.pkgファイルを実行すると/Applicationsディレクトリにインストーラーがインストールされる。インストーラーを実行することで古いmacOSを上書きインストールできる。

-   [Sierra 10.12](http://updates-http.cdn-apple.com/2019/cert/061-39476-20191023-48f365f4-0015-4c41-9f44-39d3d2aca067/InstallOS.dmg)
-   [El Capitan 10.11](http://updates-http.cdn-apple.com/2019/cert/061-41424-20191024-218af9ec-cf50-4516-9011-228c78eda3d2/InstallMacOSX.dmg)
-   [Yosemite 10.10](http://updates-http.cdn-apple.com/2019/cert/061-41343-20191023-02465f92-3ab5-4c92-bfe2-b725447a070d/InstallMacOSX.dmg)
-   [Mountain Lion 10.8](https://updates.cdn-apple.com/2021/macos/031-0627-20210614-90D11F33-1A65-42DD-BBEA-E1D9F43A6B3F/InstallMacOSX.dmg)
-   [Lion 10.7](https://updates.cdn-apple.com/2021/macos/041-7683-20210614-E610947E-C7CE-46EB-8860-D26D71F0D3EA/InstallMacOSX.dmg)

## [起動可能なインストーラの作成も行える](https://support.apple.com/ja-jp/HT201372)

古いバージョンではエラーになってインストールが実行できない場合がある。その場合は起動可能なインストーラを作成して`option`キーを押下したまま再起動することでインストーラを実行できる。

## High Sierraのインストーラを作成する

インストーラに付属している`createinstallmedia`コマンドで外部メディアを起動可能なインストーラにすることができる。

```sh
sudo /Applications/Install\ OS\ X\ El\ Capitan.app/Contents/Resources/createinstallmedia \
  --volume /Volumes/MyVolume \
  --nointeraction
Erasing Disk: 0%... 10%... 20%... 30%...100%...
Copying installer files to disk...
Copy complete.
Making disk bootable...
Copying boot files...
Copy complete.
Done.
```

## Sierraのインストーラを作成する

Sierra以前は`--applicationpath`オプションでインストーラーアプリのパスを指定する必要がある。

Sierraのインストーラを作成しようとして同様に`createinstallmedia`を実行するとエラーになる。

```sh
$ sudo /Applications/Install\ macOS\ Sierra.app/Contents/Resources/createinstallmedia \
  --volume /Volumes/Media \
  --applicationpath /Applications/Install\ macOS\ Sierra.app
/Volume/Media is not a valid volume mount point.
```

Info.plistのバージョンが違っているの原因のためバージョンを書き換えることで実行できるようになる。

```sh
$ sudo plutil \
  -replace CFBundleShortVersionString \
  -string "12.6.03" /Applications/Install\ macOS\ Sierra.app/Contents/Info.plist
$ sudo /Applications/Install\ macOS\ Sierra.app/Contents/Resources/createinstallmedia \
  --volume /Volumes/Media \
  --applicationpath /Applications/Install\ macOS\ Sierra.app \
  --nointeraction
Erasing Disk: 0%... 10%... 20%... 30%...100%...
Copying installer files to disk...
Copy complete.
Making disk bootable...
Copying boot files...
Copy complete.
Done.
```

## El Capitanのインストーラを作成する

```sh
sudo /Applications/Install\ OS\ X\ El\ Capitan.app/Contents/Resources/createinstallmedia \
  --volume /Volumes/MyVolume \
  --applicationpath /Applications/Install\ OS\ X\ El\ Capitan.app \
  --nointeraction
Erasing Disk: 0%... 10%... 20%... 30%...100%...
Copying installer files to disk...
Copy complete.
Making disk bootable...
Copying boot files...
Copy complete.
Done.
```

## Yosemiteのインストーラを作成する

```sh
sudo /Applications/Install\ OS\ X\ Yosemite.app/Contents/Resources/createinstallmedia \
  --volume /Volumes/MyVolume \
  --applicationpath /Applications/Install\ OS\ X\ Yosemite.app \
  --nointeraction
Erasing Disk: 0%... 10%... 20%... 30%...100%...
Copying installer files to disk...
Copy complete.
Making disk bootable...
Copying boot files...
Copy complete.
Done.
```

## Mavericksのインストーラを作成する

Mavericksはディスクイメージ (.dmg) が[Appleのウェブサイト](https://support.apple.com/ja-jp/HT211683)上に存在しないが、過去にApp Storeからダウンロードしたことがあれば`mas`コマンドでダウンロードできる。

```sh
$ brew install mas
$ mas install 675248567
==> Downloading OS X Mavericks
==> Installed OS X Mavericks
$ sudo /Applications/Install\ OS\ X\ Mavericks.app/Contents/Resources/createinstallmedia \
  --volume /Volumes/MyVolume \
  --applicationpath /Applications/Install\ OS\ X\ Mavericks.app \
  --nointeraction
Erasing Disk: 0%... 10%... 20%... 30%...100%...
Copying installer files to disk...
Copy complete.
Making disk bootable...
Copying boot files...
Copy complete.
Done.
```

## Mountain Lionのインストーラを作成する

Mountain Lionのインストーラを作成する場合は`createinstallmedia`のコマンドがないため、`asr`コマンドでディスクイメージを復元する。

```sh
$ sudo asr restore \
  --source /Applications/Install\ OS\ X\ Lion.app/Contents/SharedSupport/InstallESD.dmg \
  --target /Volumes/Media \
  --erase --noprompt
    Validating target...done
    Validating source...done
    Retrieving scan information...done
    Validating sizes...done
    Restoring  ....10....20....30....40....50....60....70....80....90....100
    Verifying  ....10....20....30....40....50....60....70....80....90....100
    Remounting target volume...done
```

## Lionのインストーラを作成する

Lionのインストーラを作成する場合はMountain Lionと同様に`asr`コマンドでディスクイメージを復元するが、チェックサムが一致しないエラーが発生するため`--noverify`オプションを付けて実行する。

```sh
$ sudo asr restore \
  --source /Applications/Install\ OS\ X\ Mountain\ Lion.app/Contents/SharedSupport/InstallESD.dmg \
  --target /Volumes/Media \
  --erase --noprompt
    Validating target...done
    Validating source...done
    Retrieving scan information...done
    Validating sizes...done
    Restoring  ....10....20....30....40....50....60....70....80....90....100
    Verifying  ....10....20....30....40....50....60....70....80....90....100
Checksum failed.
Expected 7425D663
but got 84E748B9
Could not restore - Invalid argument
$ sudo asr restore \
  --source /Applications/Install\ OS\ X\ Mountain\ Lion.app/Contents/SharedSupport/InstallESD.dmg \
  --target /Volumes/Media \
  --erase --noprompt --noverify
    Validating target...done
    Validating source...done
    Retrieving scan information...done
    Validating sizes...done
    Restoring  ....10....20....30....40....50....60....70....80....90....100
    Verifying  ....10....20....30....40....50....60....70....80....90....100
    Remounting target volume...done
```
