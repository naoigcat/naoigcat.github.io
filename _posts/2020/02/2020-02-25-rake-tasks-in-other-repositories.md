---
layout: post
title:  別ディレクトリにあるRakeタスクを実行する
date:   2020/02/25 21:32:40 +0900
tags:   ruby
---

## Rakeタスクを実行するタスクを定義する

カレントディレクトリ以外にRakefileを置きたい場合、特にgit管理のためにリポジトリを分けたい場合は以下のようなRakefileを用意することで別ディレクトリのRakeタスクを呼び出すことができる。

```ruby
class << Rake.application
  def invoke_task(task_string)
    name, args = parse_task_string(task_string)
    t = self[name]
    t.invoke(*args)
  rescue RuntimeError => e
    raise e unless e.message =~ /Don't know how to build task/

    t = self[default_task_name]
    t.invoke(task_string)
  end
end

desc "Run task"
task :default, [:paths, :name] do |_, arguments|
  raise "missing required arguments 'paths'" unless arguments.paths

  require "pathname"
  require "shellwords"
  arguments.with_defaults(name: "default")
  arguments.paths.split(",").map(&Pathname.method(:new)).each do |path|
    next unless path.exist?

    cd path do
      sh "source ~/.bash_profile && rake #{Shellwords.escape(arguments.name)} || :"
    end
  end
end
```
