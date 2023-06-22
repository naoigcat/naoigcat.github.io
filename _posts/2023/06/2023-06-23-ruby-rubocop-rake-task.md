---
layout: post
title:  RuboCopのRakeタスクを追加する
date:   2023/06/23 06:00:01 +0900
tags:   ruby
---

## [RuboCop](https://github.com/rubocop/rubocop)にはデフォルトのRakeタスクが用意されている

RuboCopをグローバルにインストールするかBundlerでインストールして`RuboCop::RakeTask.new`を呼ぶとタスクが生成される。

```ruby
# Gemfile
source "https://rubygems.org/"
gem "rake"
gem "rubocop"
```

```ruby
# Rakefile
require "rubocop/rake_task"
RuboCop::RakeTask.new
```

```sh
$ rake --tasks
rake rubocop                  # Run RuboCop
rake rubocop:autocorrect      # Autocorrect RuboCop offenses (only when it's safe)
rake rubocop:autocorrect_all  # Autocorrect RuboCop offenses (safe and unsafe)
```

### rake rubocop

RuboCopを実行してレポートを出力する。

### rake rubocop:autocorrect

自動修正可能なものが修正される。挙動が変わってしまう可能性のある安全ではない修正は実施されない。

### rake rubocop:autocorrect_all

自動修正可能なものが修正される。挙動が変わってしまう可能性のある安全ではない修正も実施される。
