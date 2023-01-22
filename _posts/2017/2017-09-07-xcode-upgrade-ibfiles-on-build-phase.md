---
layout: post
title:  Xcodeでのビルド時にInterface Builderファイルを更新する
date:   2017/09/07 02:33:00 +0900
tags:   xcode
---

Interface Builderで編集するXib/StoryboardファイルにはXcodeのバージョンが含まれているため、Xcodeをアップデートして開くと差分が出てしまう。

こうした差分はレビューの邪魔になるのでビルド時に全ファイルをXcode付属のibtoolで更新するようにしてみる。

1.  Homebrewでxmlstarletをインストールしておく。XMLファイルの内容を読み取るのに使用する。

    ```sh
    brew install xmlstarlet
    ```

2.  実行したいTargetのBuild PhasesでRun Scriptを追加し、下記のスクリプトを実行させる。

    ```sh
    if ! which xml >/dev/null; then
        echo "warning: xmlstarlet does not exist, do brew install xmlstarlet"
        exit
    fi

    tools_version=$(ibtool --version | xml sel -t -v "//dict/dict/key[text()='bundle-version']/following::string[1]" 2>/dev/null)
    system_version=$(sw_vers -buildVersion)

    find . -name "*.storyboard" -or -name "*.xib" |
    while read filename
    do
        if [ "$(xml sel -t -v '//document/@toolsVersion' $filename)" -eq "$tools_version" ]; then
            continue
        fi
        if [ "$(xml sel -t -v '//document/@systemVersion' $filename)" -eq "$system_version" ]; then
            continue
        fi
        echo "Upgrade $filename"
        xcrun ibtool --upgrade $filename --write $filename
    done
    ```
