---
layout: post
title:  RubyでmacOSの連絡先からvCard形式のファイルを生成する
date:   2020/03/24 23:50:11 +0900
tags:   ruby
---

macOSの連絡先からvCard形式のファイルを生成するRubyスクリプト。過去に使用していたもの。

```ruby
class String
  def undent
    gsub(/^.{#{(slice(/^ +/) || '').length}}/, "")
  end
end

require "pathname"
require "shellwords"
Pathname.new("/path/to/target.vcf").open("w+b", encoding: "sjis:utf-8") do |stream|
  Pathname.glob("#{ENV["HOME"]}/Library/Application Support/AddressBook/**/*.abcddb").map do |path|
    IO.popen(Shellwords.join(["/usr/bin/sqlite3", path]), "r+") do |io|
      io.write <<-SQL.undent
        SELECT    ZLASTNAME || " " || ZFIRSTNAME, ZPHONETICLASTNAME || " " || ZPHONETICFIRSTNAME, ZFULLNUMBER, ZADDRESS
        FROM      ZABCDRECORD
        LEFT JOIN ZABCDPHONENUMBER ON ZABCDPHONENUMBER.ZOWNER = ZABCDRECORD.Z_PK
        LEFT JOIN ZABCDEMAILADDRESS ON ZABCDEMAILADDRESS.ZOWNER = ZABCDRECORD.Z_PK
        WHERE     (ZLASTNAME IS NOT NULL)
        AND       (ZABCDPHONENUMBER.ZLABEL <> "_$!<Other>!$_" OR ZABCDPHONENUMBER.ZLABEL IS NULL)
        AND       (ZABCDEMAILADDRESS.ZLABEL <> "_$!<Other>!$_" OR ZABCDEMAILADDRESS.ZLABEL IS NULL)
        ;
      SQL
      io.close_write
      io.read
    end
  end.delete_if(&:empty?).join.scan(/^(.*?)\|(.*?)\|(.*?)\|(.*?)$/).group_by(&:first).each do |_, person|
    name, sort, call, mail = person.transpose.map!(&:uniq)
    stream.write <<-VCARD.undent.gsub(/\n+/, "\r\n").tr(" ", "\u0020")
      BEGIN:VCARD
      VERSION:2.1
      N;CHARSET=SHIFT_JIS:#{name.first};;;;
      SOUND;X-IRMC-N;CHARSET=SHIFT_JIS:#{sort.first.gsub(
        /[\u30a1-\u30fc]/,
        "\u30a1" => "\uff67",
        "\u30a2" => "\uff71",
        "\u30a3" => "\uff68",
        "\u30a4" => "\uff72",
        "\u30a5" => "\uff69",
        "\u30a6" => "\uff73",
        "\u30a7" => "\uff6a",
        "\u30a8" => "\uff74",
        "\u30a9" => "\uff6b",
        "\u30aa" => "\uff75",
        "\u30ab" => "\uff76",
        "\u30ac" => "\uff76\uff9e",
        "\u30ad" => "\uff77",
        "\u30ae" => "\uff77\uff9e",
        "\u30af" => "\uff78",
        "\u30b0" => "\uff78\uff9e",
        "\u30b1" => "\uff79",
        "\u30b2" => "\uff79\uff9e",
        "\u30b3" => "\uff7a",
        "\u30b4" => "\uff7a\uff9e",
        "\u30b5" => "\uff7b",
        "\u30b6" => "\uff7b\uff9e",
        "\u30b7" => "\uff7c",
        "\u30b8" => "\uff7c\uff9e",
        "\u30b9" => "\uff7d",
        "\u30ba" => "\uff7d\uff9e",
        "\u30bb" => "\uff7e",
        "\u30bc" => "\uff7e\uff9e",
        "\u30bd" => "\uff7f",
        "\u30be" => "\uff7f\uff9e",
        "\u30bf" => "\uff80",
        "\u30c0" => "\uff80\uff9e",
        "\u30c1" => "\uff81",
        "\u30c2" => "\uff81\uff9e",
        "\u30c3" => "\uff6f",
        "\u30c4" => "\uff82",
        "\u30c5" => "\uff82\uff9e",
        "\u30c6" => "\uff83",
        "\u30c7" => "\uff83\uff9e",
        "\u30c8" => "\uff84",
        "\u30c9" => "\uff84\uff9e",
        "\u30ca" => "\uff85",
        "\u30cb" => "\uff86",
        "\u30cc" => "\uff87",
        "\u30cd" => "\uff88",
        "\u30ce" => "\uff89",
        "\u30cf" => "\uff8a",
        "\u30d0" => "\uff8a\uff9e",
        "\u30d1" => "\uff8a\uff9f",
        "\u30d2" => "\uff8b",
        "\u30d3" => "\uff8b\uff9e",
        "\u30d4" => "\uff8b\uff9f",
        "\u30d5" => "\uff8c",
        "\u30d6" => "\uff8c\uff9e",
        "\u30d7" => "\uff8c\uff9f",
        "\u30d8" => "\uff8d",
        "\u30d9" => "\uff8d\uff9e",
        "\u30da" => "\uff8d\uff9f",
        "\u30db" => "\uff8e",
        "\u30dc" => "\uff8e\uff9e",
        "\u30dd" => "\uff8e\uff9f",
        "\u30de" => "\uff8f",
        "\u30df" => "\uff90",
        "\u30e0" => "\uff91",
        "\u30e1" => "\uff92",
        "\u30e2" => "\uff93",
        "\u30e3" => "\uff6c",
        "\u30e4" => "\uff94",
        "\u30e5" => "\uff6d",
        "\u30e6" => "\uff95",
        "\u30e7" => "\uff6e",
        "\u30e8" => "\uff96",
        "\u30e9" => "\uff97",
        "\u30ea" => "\uff98",
        "\u30eb" => "\uff99",
        "\u30ec" => "\uff9a",
        "\u30ed" => "\uff9b",
        "\u30ee" => "",
        "\u30ef" => "\uff9c",
        "\u30f0" => "",
        "\u30f1" => "",
        "\u30f2" => "\uff66",
        "\u30f3" => "\uff9d",
        "\u30f4" => "\uff73\uff9e",
        "\u30f5" => "",
        "\u30f6" => "",
        "\u30f7" => "\uff9c\uff9e",
        "\u30f8" => "",
        "\u30f9" => "",
        "\u30fa" => "\uff66\uff9e",
        "\u30fb" => "\uff65",
        "\u30fc" => "\uff70",
      )};;;;
      #{call.join("\n").gsub(/^[^\n]/, "TEL;CELL:\\&")}
      #{mail.join("\n").gsub(/^[^\n]/, "EMAIL;WORK:\\&")}
      END:VCARD
    VCARD
  end
end
```
