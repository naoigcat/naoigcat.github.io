source "https://rubygems.org"
require "json"
require "open-uri"
JSON.parse(open("https://pages.github.com/versions.json").read).each do |name, version|
  if name == "ruby"
    ruby version
  else
    gem name, version
  end
end
