---
layout: post
title:  Rubyスクリプト内でインストールしたGemを使用する
date:   2023/01/27 10:16:12 +0900
tags:   swift
---

## インストール直後はロードできない

Rubyスクリプト内でGemをインストールして直後にロードしようとしても`LoadError`になる。

```rb
sh "gem", "install", "--no-document", "bundler"
require "bundler"
# => in `require': cannot load such file -- minitest (LoadError)
```

## 読み込みパスをクリアするとロードできるようになる

`Gem.clear_paths`で読み込みパスをクリアするとロードできるようになる。

```rb
begin
  require "bundler"
rescue LoadError
  sh "gem", "install", "--no-document", "bundler"
  Gem.clear_paths
  retry
end
```

## バージョンを指定することもできる

`gem`メソッドを使用すればバージョンも指定してロードできる。

```rb
begin
  gem "bundler", "2.4.5"
rescue Gem:::MissingSpecError
  sh "gem", "install", "--no-document", "bundler", "-v", "2.4.5"
  Gem.clear_paths
  retry
end
```
