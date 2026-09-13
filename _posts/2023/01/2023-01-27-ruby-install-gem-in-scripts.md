---
title:     Rubyスクリプト内でインストールしたGemを使用する
date:      2023-01-27 10:16:12 +0900
tags:      ruby
---

## インストール直後はロードできない

Rubyスクリプト内でGemをインストールして直後にロードしようとしても`LoadError`になる。（`system` で `gem install` を呼ぶ例。Rake の `sh` でも同様。）

```ruby
system("gem", "install", "--no-document", "bundler")
require "bundler"
# => in `require': cannot load such file -- bundler (LoadError)
```

## 読み込みパスをクリアするとロードできるようになる

`Gem.clear_paths`で読み込みパスをクリアするとロードできるようになる。

```ruby
begin
  require "bundler"
rescue LoadError
  system("gem", "install", "--no-document", "bundler") or raise
  Gem.clear_paths
  retry
end
```

## バージョンを指定することもできる

`gem`メソッドを使用すればバージョンも指定してロードできる。

```ruby
begin
  gem "bundler", "2.4.5"
rescue Gem::MissingSpecError
  system("gem", "install", "--no-document", "bundler", "-v", "2.4.5") or raise
  Gem.clear_paths
  retry
end
```
