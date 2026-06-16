# frozen_string_literal: true

module Jekyll
  class TagPageGenerator < Generator
    safe true

    def generate(site)
      site.tags.each_key do |tag|
        site.pages << TagPage.new(site, tag)
      end
    end
  end

  class TagPage < Page
    def initialize(site, tag)
      @site = site
      @base = site.source
      slug = Jekyll::Utils.slugify(tag)
      @dir = File.join("tags", slug)
      @name = "index.html"

      self.process(@name)
      self.data = {
        "layout" => "tag",
        "tag" => tag
      }
    end
  end
end
