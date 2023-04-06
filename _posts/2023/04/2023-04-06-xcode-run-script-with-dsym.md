---
layout: post
title:  XcodeがdSYMファイルを生成した後にスクリプトを実行する
date:   2023/04/06 12:04:06 +0900
tags:   xcode
---

## Xcode 10以降ではビルドの成果物は明示的に依存させる必要がある

Xcode 10の[New Feature](https://developer.apple.com/documentation/xcode_release_notes/xcode_10_release_notes/build_system_release_notes_for_xcode_10#3035615)で説明されている通り、Info.plistや.dSYMのようなビルドフェイズの成果物に依存する場合はインプットとして明示的に指定する必要があるようになった。

指定していない場合は参照しても空ファイルになる。

## Crashlyticsに.dSYMファイルをアップロードする

Swift Package ManagerでFirebaseをインストールしている場合は`New Run Script Phase`で下記の内容を入力し、

```sh
${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run
```

`Based on dependency analysis`にチェックを入れて`Input Files`に

```sh
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}
```

を入れることでビルド時に.dSYMファイルをアップロードできる。
