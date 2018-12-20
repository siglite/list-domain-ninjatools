#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'bundler/setup'
require 'http'
require 'oga'

Domain = Struct.new(:name, :length, :comment)

def http_stream(url)
  Enumerator.new do |e|
    HTTP.get(url).body.each do |chunk|
      e << chunk
    end
  end
end

def parse_domain(stream, selector, regexp)
  Oga.parse_html(stream).css(selector).map do |e|
    if regexp =~ e.text then
      length = $1.length
      Domain.new($1, length, $2)
    else
      STDERR.puts "Not match: #{e.text}"
      exit
    end
  end
end

def generate_table(domains)
  min, max = domains.minmax_by {|e| e.length}.map {|e| e.length}

  (min..max).map do |n|
    dn = domains.select { |e| e.length == n }.sort_by { |e| e.name }
    next if dn.length == 0

    header = <<-EOS
## #{n} characters

| domain | comment |
|:------:|:--------|
    EOS

    s = dn.map { |e| "| `#{e.name}` | #{e.comment} |" }.join("\n")

    header + s + "\n"
  end.compact.join("\n")
end

regex  = /\A([\w\.-]+) ?（(.+)）\Z/
hp   = http_stream("https://www.ninja.co.jp/hp/selectable-domain")
blog = http_stream("https://www.ninja.co.jp/blog/selectable-domain")

File.open("doc/ninja_hp.md", "w") do |f|
  f.write "# 忍者ホームページ - ドメインリスト\n"
  f.write generate_table(parse_domain(hp, "td", regex))
end

File.open("doc/ninja_blog.md", "w") do |f|
  f.write "# 忍者ブログ - ドメインリスト\n"
  f.write generate_table(parse_domain(blog, "td", regex))
end
