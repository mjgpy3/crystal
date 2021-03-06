#!/usr/bin/env bin/crystal --run
require "spec"
require "cgi"

describe "CGI" do
  [
    {"hello", "hello"},
    {"hello+world", "hello world"},
    {"hello%", "hello%"},
    {"hello%2", "hello%2"},
    {"hello%2B", "hello+"},
    {"hello%2Bworld", "hello+world"},
    {"hello%2%2Bworld", "hello%2+world"},
    {"%E3%81%AA%E3%81%AA", "なな"},
    {"%e3%81%aa%e3%81%aa", "なな"},
    {"%27Stop%21%27+said+Fred", "'Stop!' said Fred"},
  ].each do |tuple|
    from, to = tuple
    it "unescapes #{from}" do
      CGI.unescape(from).should eq(to)
    end
  end

  [
    {"hello", "hello"},
    {"hello+world", "hello world"},
    {"hello%25", "hello%"},
    {"hello%252", "hello%2"},
    {"hello%2b", "hello+"},
    {"hello%2bworld", "hello+world"},
    {"hello%252%2bworld", "hello%2+world"},
    {"%e3%81%aa%e3%81%aa", "なな"},
    {"%27Stop%21%27+said+Fred", "'Stop!' said Fred"},
  ].each do |tuple|
    from, to = tuple
    it "escapes #{to}" do
      CGI.escape(to).should eq(from)
    end
  end

  [
    { "foo=bar", {"foo" => ["bar"]} },
    { "foo=bar&foo=baz", {"foo" => ["bar", "baz"]} },
    { "foo=bar&baz=qux", {"foo" => ["bar"], "baz" => ["qux"]} },
    { "foo=bar;baz=qux", {"foo" => ["bar"], "baz" => ["qux"]} },
    { "foo=hello%2Bworld", {"foo" => ["hello+world"]} },
    { "foo=", {"foo" => [""]} },
    { "foo", {"foo" => [""]} },
  ].each do |tuple|
    from, to = tuple
    it "parses #{from}" do
      CGI.parse(from).should eq(to)
    end
  end
end
