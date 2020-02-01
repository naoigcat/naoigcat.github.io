---
layout: post
title:  RubyでGoogle Driveからファイルをダウンロードする
date:   2017-09-17 22:11:00 +0900
tags:   ruby, google-drive
---

RubyでGoogle Driveからファイルをダウンロードする方法はいくつかあるがOAuthを使用する場合は以下のようなコードになる。

```ruby
def authorize(scope)
  require "googleauth"
  require "googleauth/stores/file_token_store"

  client_id   = Google::Auth::ClientId.new("", "")
  token_store = Google::Auth::Stores::FileTokenStore.new(file: "")
  authorizer  = Google::Auth::UserAuthorizer.new(client_id, scope, token_store)
  user_id     = "default"

  credentials = authorizer.get_credentials(user_id)
  return credentials unless credentials.nil? or credentials.expires_at < Time.current

  base_url = "urn:ietf:wg:oauth:2.0:oob"
  url = authorizer.get_authorization_url(base_url: base_url)
  puts "Open the following URL in the browser and enter the resulting code after authorization", url
  authorizer.get_and_store_credentials_from_code(user_id: user_id, code: STDIN.gets, base_url: base_url)
end

require "google/apis/drive_v3"
service = Google::Apis::DriveV3::DriveService.new
service.client_options.application_name = "Application"
service.authorization = authorize(Google::Apis::DriveV3::AUTH_DRIVE)

query = "name = 'directory' and trashed = false and 'me' in owners"
directory = service.list_files(q: query, page_size: 10).files.first
return unless directory

query = "parents = '#{directory.id}' and trashed = false and 'me' in owners"
file = service.list_files(q: query, page_size: 10).files.first
return unless file

service.get_file(file.id, download_dest: file.name)
```
