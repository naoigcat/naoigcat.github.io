---
layout: post
title:  別のリポジトリにあるRakeタスクを実行する
date:   2020/02/25 21:32:40 +0900
tags:   ruby
---

現在いるディレクトリ以外にRakefileを置きたい場合、特にgit管理のためにリポジトリを分けたい場合は以下のようなRakefileを用意することで別ディレクトリのRakeタスクを呼び出すことができる。

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
task :default, [:name] do |_, arguments|
  raise "missing required arguments 'name'" unless arguments.name

  require "pathname"
  require "shellwords"
  %w[Desktop Developer Documents].each do |directory|
    path = Pathname.new(ENV["HOME"]).join(directory).join("rake-tasks")
    next unless path.exist?

    cd path do
      sh "source ~/.bash_profile && rbenv shell $(cat .ruby-version) && rake #{Shellwords.escape(arguments.name)} || :"
    end
  end
end
```
