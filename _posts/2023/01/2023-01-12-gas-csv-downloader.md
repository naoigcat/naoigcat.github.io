---
layout: post
title:  Google Sheetで文字コードをShift JISにしたCSVをダウンロードする
date:   2023/01/12 12:10:28 +0900
tags:   google gas
---

## CSV形式でダウンロードするとUTF-8になる

Google SheetでシートをCSV形式でダウンロードするとき文字コードはUTF-8固定になる。

Windowsアプリケーションで利用する場合などでShift JISでエンコードされている必要がある場合がある。

## GASで文字コードを変換してダウンロードする

下記のコードをGoogle App Scriptに実装することでシートを開いたときにDownloadメニューが追加される。

メニューをクリックするとモーダルが表示されてDownloadリンクからシート名がファイル名になったCSVファイルがダウンロードできる。

```js
// download.gs
function onOpen() {
  const spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
  spreadsheet.addMenu("Download", [
    {
      name: "CSV (Shift JIS)",
      functionName: "download",
    },
  ]);
}

function download() {
  const sheet = SpreadsheetApp.getActiveSheet();
  const template = HtmlService.createTemplateFromFile("download");
  template.values = JSON.stringify(sheet.getDataRange().getValues());
  template.name = sheet.getName();
  SpreadsheetApp.getUi().showModalDialog(
    template.evaluate(),
    "CSV (Shift JIS)"
  );
}
```

```html
<!-- download.html -->
<!DOCTYPE html>
<html>
  <head>
    <base target="_top">
  </head>
  <body>
    <a id="download" href="#" download="<?= name ?>.csv" target="_blank">Download</a>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/PapaParse/5.3.2/papaparse.min.js"
      integrity="sha512-SGWgwwRA8xZgEoKiex3UubkSkV1zSE1BS6O4pXcaxcNtUlQsOmOmhVnDwIvqGRfEmuz83tIGL13cXMZn6upPyg=="
    crossorigin="anonymous"
 referrerpolicy="no-referrer"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/encoding-japanese/2.0.0/encoding.min.js"
      integrity="sha512-AhAMtLXTbhq+dyODjwnLcSlytykROxgUhR+gDZmRavVCNj6Gjta5l+8TqGAyLZiNsvJhh3J83ElyhU+5dS2OZw=="
    crossorigin="anonymous"
 referrerpolicy="no-referrer"></script>
    <script>
      const values = JSON.parse(<?= values ?>);
      const csv = Encoding.convert(Papa.unparse(values), {
        from: "UNICODE",
        to: "SJIS",
        type: "array"
      });
      const blob = new Blob([new Uint8Array(csv)], { type: "text/csv" });
      window.URL = window.URL || window.webkitURL;
      document.getElementById("download").href = window.URL.createObjectURL(blob);
    </script>
  </body>
</html>
```
