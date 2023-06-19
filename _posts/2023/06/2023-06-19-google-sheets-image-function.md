---
layout: post
title:  スプレッドシートでIMAGE関数を使用する
date:   2023/06/19 14:55:57 +0900
tags:   google
---

## IMAGE関数を使用する

IMAGE関数を使用するとセルに画像を挿入することができる。

## 構文

```google
IMAGE(URL, [モード], [高さ], [幅])
```

### URL

画像のURL。Google Drive上にある画像を表示する場合、共有URL <https://drive.google.com/file/d/xxx> は指定できず、ダウンロードURL <https://drive.google.com/uc?export=download&id=xxx> を指定する必要があるが、共有設定を「リンクを知っている全員」が閲覧可能にする必要がある。

### モード（省略可、デフォルト1）

-   `1` アスペクト比を維持しながらセル内に収まるように画像のサイズを変更する
-   `2` アスペクト比を無視してセル内に収まるように画像を引き伸ばすか縮める
-   `3` は画像を元のサイズのままにし、セル内に収まらない部分はトリミングされる
-   `4` はカスタムサイズに変更できる

### 高さ

モード4のときの画像の高さをピクセルで指定する。

### 幅

モード4のときの画像の幅をピクセルで指定する。

## GASでGoogle Drive上の画像を表示することもできる

Google Drive上の画像をIMAGE関数でセル内に表示する場合は共有設定を「リンクを知っている全員」が閲覧可能にする必要があり、セキュリティ的によくない場合にはIMAGE関数を使用できない。

GASで共有設定を変更せずにGoogle Drive上にある画像を表示することができる。

```js
/**
 * 画像ファイルへのURLからセル内に画像を貼り付ける
 *
 * @param {String} name シート名
 * @param {Number} source ファイルのドライブ上のURL (https://drive.google.com/file/d/{fileId}) が入っている列番号
 * @param {Number} target 画像を出力する列番号
 * @param {Number} header ヘッダーの行数
 */
function generate(name, source, target, header=1) {
  const sheet = SpreadsheetApp.getActive().getSheetByName(name);
  let images = sheet.getRange(header + 1, source, sheet.getLastRow() - header, 1).getValues().map(row => {
    return row.map(url => {
      if (!url || url.length < 65) {
        return ""
      }
      let file = url.toString().substring(32, 65);
      Logger.log(file);
      let blob = DriveApp.getFileById(file).getBlob();
      let data = `data:${blob.getContentType()};base64,${Utilities.base64Encode(blob.getBytes())}`;
      return SpreadsheetApp.newCellImage()
        .setSourceUrl(data)
        .build()
        .toBuilder();
    });
  });
  sheet.getRange(header + 1, target, sheet.getLastRow() - header, 1).setValues(images);
}
```
