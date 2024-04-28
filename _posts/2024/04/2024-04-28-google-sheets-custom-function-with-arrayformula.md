---
layout: post
title:  Google SheetsでARRAYFORMULAにカスタム関数を渡す
date:   2024/04/28 14:42:30 +0900
tags:   google
---

## カスタム関数を呼び出す

Google Apps Scriptで関数を定義するとGoogle Sheetsのセルから呼び出すことができる。

```javascript
function CUSTOM(value) {
    return value + 1;
}
```

上記のように定義するとセルで`=CUSTOM(1)`とすると`2`が表示される。

## カスタム関数をARRAYFORMULAに対応させる

`ARRAYFORMULA`でカスタム関数を呼び出すと引数には配列が渡される。

カスタム関数で渡された引数が配列かどうかで処理を変えることで単一セルで呼び出された場合と`ARRAYFORMULA`で呼び出された場合の両方に対応できる。

```javascript
function GETLINK(rows, columns) {
  if (Array.isArray(rows)) {
    return rows.map(row => {
      if (Array.isArray(columns)) {
        return columns.map(column => {
          return GETLINK(row, column);
        });
      } else {
        return GETLINK(row, columns);
      }
    });
  } else if (Array.isArray(columns)) {
    return columns.map(column => {
      return GETLINK(rows, column);
    });
  } else {
    return SpreadsheetApp.getActiveSheet().getRange(rows, columns).getRichTextValue().getLinkUrl();
  }
}
```
