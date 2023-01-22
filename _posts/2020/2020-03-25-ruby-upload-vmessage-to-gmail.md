---
layout: post
title:  RubyでvMessage形式のメールをGmailにアップロードする
date:   2020/03/25 00:11:12 +0900
tags:   ruby
---

vMessage形式のメールをGmailにアップロードするスクリプト。過去に使っていたもの。

```ruby
class String
  def undent
    gsub(/^.{#{(slice(/^ +/) || '').length}}/, "")
  end
end

require "io/console"
require "net/imap"
require "pathname"
source = "naoigcat@example.com"
target = "naoigcat@gmail.com"
pass = proc do
  next STDIN.readline unless STDIN.tty?

  puts "Enter password for #{target}"
  loop.reduce("") do |s|
    case c = STDIN.getch
    when /[\x03]/
      Process.kill("SIGINT", Process.pid)
    when /[\x1a]/
      Process.kill("SIGSTOP", Process.pid)
    when /[\x08\x7f]/
      print "\b \b"
      s.chop
    when /[\x15]/
      print "\b \b" * s.length
      ""
    when /[\x0a\x0d]/
      print "\n"
      break s
    when /[\x1b]/
      case STDIN.getch
      when "["
        until STDIN.getch.match?(/[\x40-\x7e]/)
        end
      end
      s
    else
      print "*"
      s + c
    end
  end
end.call
imap = Net::IMAP.new("imap.gmail.com", 993, true)
imap.login(target, pass)
imap.select("Messages")
imap.expunge
mbox = Pathname.glob("/path/to/*.VMG")
mbox = mbox.each_with_object(encoding: "sjis:utf-8", universal_newline: true, invalid: :replace)
mbox = mbox.map(&:read)
mbox = mbox.join
mbox = mbox.force_encoding("utf-8")
mbox = mbox.gsub(/\u{22 ff61 30 fffd}.*\u{fffd 20 20 e39e}/, target)
mbox = mbox.gsub(/\r\n/, "\n")
mbox = mbox.gsub(/^From: $/, "From: #{source}")
mbox = mbox.gsub(/^(Content-Type: .+)Shift_JIS/, "\\1UTF-8")
mbox = mbox.gsub(/Content-Type: text\/html; charset=UTF-8\nContent-Transfer-Encoding: 8bit\n\n/, "")
mbox = mbox.gsub(/Content-Type: multipart\/(?:related|mixed); boundary="([0-9-]+)"\n\n--\1\n(.*?)--\1--\n\n/m, "\\2")
mbox = mbox.gsub(/Content-Type: multipart\/alternative; boundary="([0-9-]+)"\n\n--\1\n(.*?)\n--\1(.*?)--\1--\n\n/m, "\\2\n\\3")
mbox = mbox.gsub(/(Content-Transfer-Encoding: 8bit)\n+/, "\\1\n\n")
mbox = mbox.gsub(/<br[^>]*>\n?/, "\n")
mbox = mbox.gsub(/<\/div><div>/, "\n")
mbox = mbox.gsub(/<blockquote/, "> \\&")
mbox = mbox.gsub(/(<blockquote(?:(?!<\/blockquote>).)*?\n)(?!<\/blockquote>)([^>])/m, "\\1> \\2") while $LAST_MATCH_INFO
mbox = mbox.gsub(/<[a-z]+(?: [a-z-]+="?[^"]+"?)*>|<\/[a-z]+>/i, "")
mbox = mbox.gsub(/&nbsp;/, "")
mbox = mbox.gsub(/&lt;/, "<")
mbox = mbox.gsub(/&gt;/, ">")
mbox = mbox.scan(/(?<=^BEGIN:VMSG\n).+?(?=END:VMSG)/m).map do |mail|
  if mail.match?(/ENCODING=QUOTED-PRINTABLE/)
    from, to = mail.scan(/(?<=^BEGIN:VCARD\n).+?(?=END:VCARD)/m).map do |card|
      card.scan(/(?<=TEL:).+/).first
    end
    date = mail.scan(/(?<=^BEGIN:VBODY\n).+?(?=END:VBODY)/m).first.lines[2].chomp[6..-1]
    body = mail.scan(/(?<=^BEGIN:VBODY\n).+?(?=END:VBODY)/m).first.lines[4..-1].join.unpack1("M").force_encoding("sjis").encode("utf-8")
    mail = <<-MESSAGE.undent.gsub(/\\n/, "\n")
      From: #{from || source}
      To: #{to || source}
      Subject:
      Date: #{date}
      Content-Type: text/plain; charset=UTF-8
      Content-Transfer-Encoding: 8bit

      #{body.gsub(/\r?\n/, "\\n")}
    MESSAGE
  else
    mail = mail.scan(/(?<=^BEGIN:VBODY\n).+?(?=END:VBODY)/m)
    case mail
    when /FR0\/TO/
      mail.gsub!(/(?:(?:From):.+\n)+/, "\\&To: #{source}\n")
    when /FR0\/CC/
      mail.gsub!(/(?:(?:From|To):.+\n)+/, "\\&Cc: #{source}\n")
    when /FR0\/BC/
      mail.gsub!(/(?:(?:From|To|Cc):.+\n)+/, "\\&Bcc: #{source}\n")
    end
  end
  mail.gsub!(/\r?\n/, "\r\n")
end
mbox = mbox.uniq
mbox -= mbox.grep(/^To: #{target}/)
mbox -= imap.fetch(imap.search("ALL"), "BODY[]").map do |mail|
  mail.attr["BODY[]"].force_encoding("utf-8")
end
mbox.each do |mail|
  time = mail.slice(/(?<=Date: ).+/).split(/[:, \r]+/)
  time = *time.values_at(3, 2, 1, 4..6), "#{time[7][0..2]}:#{time[7][3..4]}"
  imap.append("Messages", mail, [:Seen], Time.new(*time))
end
```
