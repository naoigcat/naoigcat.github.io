---
layout: post
title:  実行中のRubyと異なるバージョンのRubyで同じコードを呼び出す
date:   2023/03/15 12:42:08 +0900
tags:   ruby asdf
---

## Rubyのバージョン切り替えを`asdf`で行う

```sh
$ brew install asdf
$ asdf install ruby 3.0.5
$ asdf shell ruby 3.0.5
$ asdf current ruby
ruby            3.0.5           ASDF_RUBY_VERSION environment variable
```

## 外部コマンド内でバージョンを切り替えて再実行する

```ruby
# Rakefile
def script
  if File.exist?("#{IO.popen("brew --prefix asdf", &:read).chomp}/libexec/asdf.sh")
    "#{IO.popen("brew --prefix asdf", &:read).chomp}/libexec/asdf.sh"
  else
    "#{IO.popen("brew --prefix asdf", &:read).chomp}/asdf.sh"
  end
end

task :default do
  puts "RUBY_VERSION=#{RUBY_VERSION}"
end

task :latest do
  exec ". #{script} && asdf shell ruby 3.1.3 && rake" if Gem::Version.new(RUBY_VERSION) < "3.1"
  Rake::Task["default"].invoke
end
```

```sh
$ rake
RUBY_VERSION=3.0.5
$ rake latest
RUBY_VERSION=3.1.3
```
