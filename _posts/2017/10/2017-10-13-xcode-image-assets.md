---
layout: post
title:  XcodeでImages.xcassets内のリンク切れをチェックする
date:   2017/10/13 17:26:00 +0900
tags:   macos xcode
---

## リンクされていないアセットを抽出する

```ruby
Pathname.glob("Images.xcassets/**/*.imageset/").each do |path|
  Pathname.glob("**/*").select do |file|
    file.file? && %w(.h .m .storyboard .xib .pbxproj .c .mm).include?(file.extname)
  end.select do |file|
    file.read.match(/#{path.basename(".imageset").to_path}("|\.)/) rescue nil
  end.tap do |files|
    puts "#{path.basename(".imageset").to_path}: #{files.map(&:to_path).join(", ")}" if files.empty?
  end
end.tap do
  break nil
end
```

## 存在しないアセットへのリンクを抽出する

```ruby
Pathname.glob("**/*").select do |file|
  file.file? && %w(.h .m .storyboard .xib .pbxproj .c .mm).include?(file.extname)
end.map do |file|
  begin
    content = file.read
    Pathname.glob("Images.xcassets/**/*.imageset/").each do |path|
      content.gsub!(/\"#{path.basename(".imageset").to_path}(\.png)?\"/, "\"\"")
    end
    file.write content
  rescue
  end
end.tap do
  break nil
end
Pathname.glob("**/*").select do |file|
  file.file?
end.select do
  file.read.match(/\.png|\.jpe?g/) rescue nil
end
```
