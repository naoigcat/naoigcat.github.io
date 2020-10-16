source "https://rubygems.org"
require "json"
require "open-uri"
JSON.parse(::URI.open("https://pages.github.com/versions.json").read).each do |name, version|
  if name == "ruby"
    ruby version.gsub(/^(?=\d)/, "~> ")
  else
    gem name, version
  end
end
