#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'bundler/setup'
require 'http'
require 'oga'
require 'json'

class Domain < Struct.new(:name, :comment)
  include Comparable

  def <=> other
    name <=> other.name
  end

  def to_json(*arg)
    { name: name, comment: comment }.to_json(*arg)
  end
end

def http_stream(url)
  Enumerator.new do |e|
    HTTP.get(url).body.each do |chunk|
      e << chunk
    end
  end
end

def parse_domain(stream, selector, regexp)
  Oga.parse_html(stream).css(selector).map do |elem|
    if regexp =~ elem.text then
      Domain.new($1, $2)
    else
      raise "[Error] Not match: #{elem.text}"
    end
  end
end

def generate_json(domains)
  JSON.pretty_generate(
    domains.group_by { |e| e.name.length }.sort.map { |k,v| [k, v.sort] }.to_h
  )
end

hp   = http_stream("https://www.ninja.co.jp/hp/selectable-domain")
blog = http_stream("https://www.ninja.co.jp/blog/selectable-domain")
re   = /\A([\w\.-]+) ?（(.+)）\Z/
css  = "td.selectable"

File.open("data/ninja_hp.json", "w") do |f|
  domains = parse_domain(hp, css, re)
  f.write generate_json(domains)
end

File.open("data/ninja_blog.json", "w") do |f|
  domains = parse_domain(blog, css, re)
  f.write generate_json(domains)
end
