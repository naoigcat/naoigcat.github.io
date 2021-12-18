---
layout: post
title:  Jekyllに別リポジトリの投稿を取り込むプラグインを追加する
date:   2021/12/19 00:20:13 +0900
tags:   shell docker
---

Jekyllは`_plugins`ディレクトリにRubyファイルを追加することでプラグインとして動作させることができる。

下記のコードで`_config.yml`の`imports_dir`ディレクトリ内にシンボリックリンクとしてリンクさせた別リポジトリのディレクトリから投稿を取り込むことができる。

```ruby
Jekyll::Hooks.register :site, :after_reset do |site|
  Dir.glob("#{site.in_source_dir("", site.config["imports_dir"])}/*").tap do |dirs|
    require 'active_support/core_ext/string/inflections'
    Jekyll.logger.info "Importing:", "#{dirs.length} #{"directory".pluralize(dirs.length)} found"
  end.each do |dir|
    posts = Jekyll::PostReader.new(site).read_posts(dir).each do |post|
      site.config["imports_dir"].split(File::SEPARATOR).each do |part|
        post.data["categories"].delete(part)
      end
    end
    site.posts.docs.concat(posts)
    Jekyll.logger.info "", "#{dir} -> #{posts.length}"
  end
end
```
