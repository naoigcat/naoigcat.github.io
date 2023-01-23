---
layout: post
title:  Rubyで固定幅のファイルをCSVとして読み込む
date:   2017/09/18 15:25:00 +0900
tags:   ruby
---

## 固定幅のファイルを読み込む

ヘッダーの長さを元に固定幅のファイルをCSVとして読み込む。

```ruby
class IO
  def read_fixedwidth(options)
    require "csv"
    string = CSV.generate do |csv|
      lengths = nil
      each do |line|
        lengths = line.split(/(?=\w)\b/).map(&:length).join("A").gsub(/^(?=\d)/, "A").gsub(/A\d+$/, "A*") if lineno == 1
        csv << line.unpack(lengths)
      end
    end
    CSV.parse(string, options)
  end
end
```
