---
title:     サービスアカウントが所有しているファイルの所有権を移す
date:      2020-11-11 16:21:46 +0900
tags:      ruby google
---

## APIで所有権を移す

サービスアカウントでGoogle Drive上に作成したファイルの所有権を移すには、API経由で所有権を移行する必要がある。

```rb
require "google_drive"
session = GoogleDrive::Session.from_service_account_key(SERVICE_ACCOUNT_KEY)
session.spreadsheets.select(&:owned_by_me?).each do |spreadsheet|
  spreadsheet.acl.push(
    {
      type: "user",
      email_address: EMAIL_ADDRESS,
      role: "owner",
    },
    transfer_ownership: true,
  )
end
```
