---
layout: post
title:  RubyでLaunchAgentsタスクを作成する
date:   2017-09-29 11:58:00 +0900
tags:   ruby, launchd
---

LaunchAgentsでタスクを登録する場合、PropertyList形式のファイルを作成するが、XMLのため作成しづらい。

Rubyでは`plist`を使用することで`Hash`をPropertyList形式に変換できる。

```ruby
class Object
  def to_pascal_case
    self
  end
end

module Enumerable
  def to_pascal_case
    map(&:to_pascal_case)
  end
end

class Hash
  def to_pascal_case
    each_with_object ({}) do |(key, value), memo|
      memo[key.to_s.split("_").map(&:capitalize).join] = value.to_pascal_case
    end
  end
end

require "plist"
options = {
  label: label,
  program_arguments: ["bash", "-c", command],
  working_directory: working_directory,
  start_calendar_interval: [
    { hour: 12, minute: 0 },
    { hour: 18, minute: 0 },
  ],
}
path = "#{ENV["HOME"]}/Library/LaunchAgents/#{options[:label]}.plist"
options.to_pascal_case.save_plist(path)
system("launchctl unload -w #{path}") if !!system("launchctl list #{options[:label]}")
system("launchctl load -w #{path}")
```
