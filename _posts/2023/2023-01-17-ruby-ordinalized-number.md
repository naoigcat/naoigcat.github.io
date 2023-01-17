---
layout: post
title:  Rubyで英語の序数詞を生成する
date:   2023/01/17 12:06:08 +0900
tags:   ruby
---

## 序数詞とは物事の順序を表す数詞である

[序数詞](https://ja.wikipedia.org/wiki/序数詞)とは、物事の数量を表す基数詞に対して物事の順序を表す数詞である。

日本語では、基数詞の前に「第」を付けたり、後に「目」や「位」を付けたりして順序を表す。

-   第1回
-   2回目
-   3位

一方、英語では基数詞に応じて異なる接尾辞を付けることで順序を表す。

-   1st
-   2nd
-   3rd

このため、プログラミング的に序数詞を生成するために個別に変換する必要がある。

## コードに落とし込む

```ruby
class Integer
  def ordinal_suffix
    mod = to_i.abs % 100
    mod %= 10 if mod > 13
    case mod
    when 0, 1, 2, 3
      %w[th st nd rd][mod]
    else
      "th"
    end
  end

  def ordinalized
    "#{self}#{ordinal_suffix}"
  end
end

puts [*-25..25, *100..113].map(&:ordinalized)
# -25th
# -24th
# -23rd
# -22nd
# -21st
# -20th
# -19th
# -18th
# -17th
# -16th
# -15th
# -14th
# -13th
# -12th
# -11th
# -10th
# -9th
# -8th
# -7th
# -6th
# -5th
# -4th
# -3rd
# -2nd
# -1st
# 0th
# 1st
# 2nd
# 3rd
# 4th
# 5th
# 6th
# 7th
# 8th
# 9th
# 10th
# 11th
# 12th
# 13th
# 14th
# 15th
# 16th
# 17th
# 18th
# 19th
# 20th
# 21st
# 22nd
# 23rd
# 24th
# 25th
# 100th
# 101st
# 102nd
# 103rd
# 104th
# 105th
# 106th
# 107th
# 108th
# 109th
# 110th
# 111th
# 112th
# 113th
```

## ライブラリを使用することもできる

ActiveSupportライブラリの`ActiveSupport::Inflector`モジュールにも`ordinalize`メソッドとして用意されている。

-   <https://api.rubyonrails.org/classes/ActiveSupport/Inflector.html#method-i-ordinalize>
-   <https://github.com/rails/rails/blob/v7.0.0/activesupport/lib/active_support/inflector/methods.rb#L347>
-   <https://github.com/rails/rails/blob/v7.0.0/activesupport/lib/active_support/locale/en.rb>
