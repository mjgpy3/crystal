#!/usr/bin/env bin/crystal --run
require "spec"

describe "String" do
  describe "[]" do
    it "gets with positive index" do
      c = "hello!"[1]
      (c.is_a?(Char)).should be_true
      c.should eq('e')
    end

    it "gets with negative index" do
      "hello!"[-1].should eq('!')
    end

    it "gets with inclusive range" do
      "hello!"[1 .. 4].should eq("ello")
    end

    it "gets with inclusive range with negative indices" do
      "hello!"[-5 .. -2].should eq("ello")
    end

    it "gets with exclusive range" do
      "hello!"[1 ... 4].should eq("ell")
    end

    it "gets with start and count" do
      "hello"[1, 3].should eq("ell")
    end

    it "gets with exclusive range with unicode" do
      "há日本語"[1 .. 3].should eq("á日本")
    end

    it "gets with exclusive with start and count" do
      "há日本語"[1, 3].should eq("á日本")
    end

    it "gets with exclusive with start and count to end" do
      "há日本語"[1, 4].should eq("á日本語")
    end

    it "gets with single char" do
      ";"[0 .. -2].should eq("")
    end
  end

  describe "byte_slice" do
    it "gets byte_slice" do
      "hello".byte_slice(1, 3).should eq("ell")
    end

    it "gets byte_slice with negative count" do
      "hello".byte_slice(1, -10).should eq("")
    end

    it "gets byte_slice with start out of bounds" do
      "hello".byte_slice(10, 3).should eq("")
    end

    it "gets byte_slice with large count" do
      "hello".byte_slice(1, 10).should eq("ello")
    end

    it "gets byte_slice with negative index" do
      "hello".byte_slice(-2, 3).should eq("lo")
    end
  end

  it "does to_i" do
    "1234".to_i.should eq(1234)
  end

  it "does to_i with base" do
    "12ab".to_i(16).should eq(4779)
  end

  it "does to_i32" do
    "1234".to_i32.should eq(1234)
  end

  it "does to_i64" do
    "1234123412341234".to_i64.should eq(1234123412341234_i64)
  end

  it "does to_u64" do
    "9223372036854775808".to_u64.should eq(9223372036854775808_u64)
  end

  it "does to_f" do
    "1234.56".to_f.should eq(1234.56_f64)
  end

  it "does to_f32" do
    "1234.56".to_f32.should eq(1234.56_f32)
  end

  it "does to_f64" do
    "1234.56".to_f64.should eq(1234.56_f64)
  end

  it "compares strings: different length" do
    "foo".should_not eq("fo")
  end

  it "compares strings: same object" do
    f = "foo"
    f.should eq(f)
  end

  it "compares strings: same length, same string" do
    "foo".should eq("fo" + "o")
  end

  it "compares strings: same length, different string" do
    "foo".should_not eq("bar")
  end

  it "interpolates string" do
    foo = "<foo>"
    bar = 123
    "foo #{bar}".should eq("foo 123")
    "foo #{ bar}".should eq("foo 123")
    "#{foo} bar".should eq("<foo> bar")
  end

  it "multiplies" do
    str = "foo"
    (str * 0).should eq("")
    (str * 3).should eq("foofoofoo")
  end

  it "multiplies with length one" do
    str = "f"
    (str * 0).should eq("")
    (str * 10).should eq("ffffffffff")
  end

  describe "downcase" do
    assert { "HELLO!".downcase.should eq("hello!") }
    assert { "HELLO MAN!".downcase.should eq("hello man!") }
  end

  describe "upcase" do
    assert { "hello!".upcase.should eq("HELLO!") }
    assert { "hello man!".upcase.should eq("HELLO MAN!") }
  end

  describe "capitalize" do
    assert { "HELLO!".capitalize.should eq("Hello!") }
    assert { "HELLO MAN!".capitalize.should eq("Hello man!") }
    assert { "".capitalize.should eq("") }
  end

  describe "chomp" do
    assert { "hello\n".chomp.should eq("hello") }
    assert { "hello\r".chomp.should eq("hello") }
    assert { "hello\r\n".chomp.should eq("hello") }
    assert { "hello".chomp.should eq("hello") }
    assert { "hello".chomp.should eq("hello") }
    assert { "かたな\n".chomp.should eq("かたな") }
    assert { "かたな\r".chomp.should eq("かたな") }
    assert { "かたな\r\n".chomp.should eq("かたな") }
  end

  describe "strip" do
    assert { "  hello  \n\t\f\v\r".strip.should eq("hello") }
    assert { "hello".strip.should eq("hello") }
    assert { "かたな \n\f\v".strip.should eq("かたな") }
    assert { "  \n\t かたな \n\f\v".strip.should eq("かたな") }
    assert { "  \n\t かたな".strip.should eq("かたな") }
    assert { "かたな".strip.should eq("かたな") }
  end

  describe "rstrip" do
    assert { "  hello  ".rstrip.should eq("  hello") }
    assert { "hello".rstrip.should eq("hello") }
    assert { "  かたな \n\f\v".rstrip.should eq("  かたな") }
    assert { "かたな".rstrip.should eq("かたな") }
  end

  describe "lstrip" do
    assert { "  hello  ".lstrip.should eq("hello  ") }
    assert { "hello".lstrip.should eq("hello") }
    assert { "  \n\v かたな  ".lstrip.should eq("かたな  ") }
    assert { "  かたな".lstrip.should eq("かたな") }
  end

  describe "empty?" do
    assert { "a".empty?.should be_false }
    assert { "".empty?.should be_true }
  end

  describe "index" do
    describe "by char" do
      assert { "foo".index('o').should eq(1) }
      assert { "foo".index('g').should be_nil }
      assert { "bar".index('r').should eq(2) }
      assert { "日本語".index('本').should eq(1) }

      describe "with offset" do
        assert { "foobarbaz".index('a', 5).should eq(7) }
        assert { "foobarbaz".index('a', -4).should eq(7) }
        assert { "foo".index('g', 1).should be_nil }
        assert { "foo".index('g', -20).should be_nil }
        assert { "日本語日本語".index('本', 2).should eq(4) }
      end
    end

    describe "by string" do
      assert { "foo bar".index("o b").should eq(2) }
      assert { "foo".index("fg").should be_nil }
      assert { "foo".index("").should eq(0) }
      assert { "foo".index("foo").should eq(0) }
      assert { "日本語日本語".index("本語").should eq(1) }

      describe "with offset" do
        assert { "foobarbaz".index("ba", 4).should eq(6) }
        assert { "foobarbaz".index("ba", -5).should eq(6) }
        assert { "foo".index("ba", 1).should be_nil }
        assert { "foo".index("ba", -20).should be_nil }
        assert { "日本語日本語".index("本語", 2).should eq(4) }
      end
    end
  end

  describe "rindex" do
    describe "by char" do
      assert { "foobar".rindex('a').should eq(4) }
      assert { "foobar".rindex('g').should be_nil }
      assert { "日本語日本語".rindex('本').should eq(4) }

      describe "with offset" do
        assert { "faobar".rindex('a', 3).should eq(1) }
        assert { "faobarbaz".rindex('a', -3).should eq(4) }
        assert { "日本語日本語".rindex('本', 3).should eq(1) }
      end
    end

    describe "by string" do
      assert { "foo baro baz".rindex("o b").should eq(7) }
      assert { "foo baro baz".rindex("fg").should be_nil }
      assert { "日本語日本語".rindex("日本").should eq(3) }

      describe "with offset" do
        assert { "foo baro baz".rindex("o b", 6).should eq(2) }
        assert { "foo baro baz".rindex("fg").should be_nil }
        assert { "日本語日本語".rindex("日本", 2).should eq(0) }
      end
    end
  end

  describe "byte_index" do
    assert { "foo".byte_index('o'.ord).should eq(1) }
    assert { "foo bar booz".byte_index('o'.ord, 3).should eq(9) }
    assert { "foo".byte_index('a'.ord).should be_nil }
  end

  describe "includes?" do
    describe "by char" do
      assert { "foo".includes?('o').should be_true }
      assert { "foo".includes?('g').should be_false }
    end

    describe "by string" do
      assert { "foo bar".includes?("o b").should be_true }
      assert { "foo".includes?("fg").should be_false }
      assert { "foo".includes?("").should be_true }
    end
  end

  describe "split" do
    describe "by char" do
      assert { "foo,bar,,baz,".split(',').should eq(["foo", "bar", "", "baz"]) }
      assert { "foo,bar,,baz".split(',').should eq(["foo", "bar", "", "baz"]) }
      assert { "foo".split(',').should eq(["foo"]) }
      assert { "foo".split(' ').should eq(["foo"]) }
      assert { "   foo".split(' ').should eq(["foo"]) }
      assert { "foo   ".split(' ').should eq(["foo"]) }
      assert { "   foo  bar".split(' ').should eq(["foo", "bar"]) }
      assert { "   foo   bar\n\t  baz   ".split(' ').should eq(["foo", "bar", "baz"]) }
      assert { "   foo   bar\n\t  baz   ".split.should eq(["foo", "bar", "baz"]) }
      assert { "   foo   bar\n\t  baz   ".split(" ").should eq(["foo", "bar", "baz"]) }
      assert { "foo,bar,baz,qux".split(',', 1).should eq(["foo,bar,baz,qux"]) }
      assert { "foo,bar,baz,qux".split(',', 3).should eq(["foo", "bar", "baz,qux"]) }
      assert { "foo,bar,baz,qux".split(',', 30).should eq(["foo", "bar", "baz", "qux"]) }
      assert { "日本語 \n\t 日本 \n\n 語".split.should eq(["日本語", "日本", "語"]) }
      assert { "日本ん語日本ん語".split('ん').should eq(["日本", "語日本", "語"]) }
    end

    describe "by string" do
      assert { "foo:-bar:-:-baz:-".split(":-").should eq(["foo", "bar", "", "baz"]) }
      assert { "foo:-bar:-:-baz".split(":-").should eq(["foo", "bar", "", "baz"]) }
      assert { "foo".split(":-").should eq(["foo"]) }
      assert { "foo".split("").should eq(["f", "o", "o"]) }
      assert { "日本さん語日本さん語".split("さん").should eq(["日本", "語日本", "語"]) }
    end
  end

  describe "starts_with?" do
    assert { "foobar".starts_with?("foo").should be_true }
    assert { "foobar".starts_with?("").should be_true }
    assert { "foobar".starts_with?("foobarbaz").should be_false }
    assert { "foobar".starts_with?("foox").should be_false }
    assert { "foobar".starts_with?('f').should be_true }
    assert { "foobar".starts_with?('g').should be_false }
    assert { "よし".starts_with?('よ').should be_true }
    assert { "よし!".starts_with?("よし").should be_true }
  end

  describe "ends_with?" do
    assert { "foobar".ends_with?("bar").should be_true }
    assert { "foobar".ends_with?("").should be_true }
    assert { "foobar".ends_with?("foobarbaz").should be_false }
    assert { "foobar".ends_with?("xbar").should be_false }
    assert { "foobar".ends_with?('r').should be_true }
    assert { "foobar".ends_with?('x').should be_false }
    assert { "よし".ends_with?('し').should be_true }
    assert { "よし".ends_with?('な').should be_false }
  end

  describe "=~" do
    it "matches with group" do
      "foobar" =~ /(o+)ba(r?)/
      $1.should eq("oo")
      $2.should eq("r")
    end
  end

  it "deletes one char" do
    deleted = "foobar".delete('o')
    deleted.bytesize.should eq(4)
    deleted.should eq("fbar")

    deleted = "foobar".delete('x')
    deleted.bytesize.should eq(6)
    deleted.should eq("foobar")
  end

  it "reverses string" do
    reversed = "foobar".reverse
    reversed.bytesize.should eq(6)
    reversed.should eq("raboof")
  end

  it "reverses utf-8 string" do
    reversed = "こんいちは".reverse
    reversed.bytesize.should eq(15)
    reversed.length.should eq(5)
    reversed.should eq("はちいんこ")
  end

  it "replaces char with string" do
    replaced = "foobar".replace('o', "ex")
    replaced.bytesize.should eq(8)
    replaced.should eq("fexexbar")
  end

  it "replaces char with string depending on the char" do
    replaced = "foobar".replace do |char|
      case char
      when 'f'
        "some"
      when 'o'
        "thing"
      when 'a'
        "ex"
      else
        nil
      end
    end
    replaced.bytesize.should eq(18)
    replaced.should eq("somethingthingbexr")
  end

  it "replaces with regex and block" do
    actual = "foo booor booooz".replace(/o+/) do |str|
      "#{str}#{str.length}"
    end
    actual.should eq("foo2 booo3r boooo4z")
  end

  it "replaces with regex and block with group" do
    actual = "foo booor booooz".replace(/(o+).*?(o+)/) do |str, match|
      "#{match[1].length}#{match[2].length}"
    end
    actual.should eq("f23r b31z")
  end

  it "replaces with regex and string" do
    "foo boor booooz".replace(/o+/, "a").should eq("fa bar baz")
  end

  it "replaces with regex and string (utf-8)" do
    "fここ bここr bここここz".replace(/こ+/, "そこ").should eq("fそこ bそこr bそこz")
  end

  it "dumps" do
    "a".dump.should eq("\"a\"")
    "\\".dump.should eq("\"\\\\\"")
    "\"".dump.should eq("\"\\\"\"")
    "\e".dump.should eq("\"\\e\"")
    "\f".dump.should eq("\"\\f\"")
    "\n".dump.should eq("\"\\n\"")
    "\r".dump.should eq("\"\\r\"")
    "\t".dump.should eq("\"\\t\"")
    "\v".dump.should eq("\"\\v\"")
    "\#{".dump.should eq("\"\\\#{\"")
    "á".dump.should eq("\"\\u{e1}\"")
    "\u{81}".dump.should eq("\"\\u{81}\"")
  end

  it "inspects" do
    "a".inspect.should eq("\"a\"")
    "\\".inspect.should eq("\"\\\\\"")
    "\"".inspect.should eq("\"\\\"\"")
    "\e".inspect.should eq("\"\\e\"")
    "\f".inspect.should eq("\"\\f\"")
    "\n".inspect.should eq("\"\\n\"")
    "\r".inspect.should eq("\"\\r\"")
    "\t".inspect.should eq("\"\\t\"")
    "\v".inspect.should eq("\"\\v\"")
    "\#{".inspect.should eq("\"\\\#{\"")
    "á".inspect.should eq("\"á\"")
    "\u{81}".inspect.should eq("\"\\u{81}\"")
  end

  it "does *" do
    str = "foo" * 10
    str.bytesize.should eq(30)
    str.should eq("foofoofoofoofoofoofoofoofoofoo")
  end

  it "does +" do
    str = "foo" + "bar"
    str.bytesize.should eq(6)
    str.should eq("foobar")
  end

  it "does %" do
    ("foo" % 1).should        eq("foo")
    ("foo %d" % 1).should     eq("foo 1")
    ("%d" % 123).should       eq("123")
    ("%+d" % 123).should      eq("+123")
    ("%+d" % -123).should     eq("-123")
    ("% d" % 123).should      eq(" 123")
    ("%20d" % 123).should     eq("                 123")
    ("%+20d" % 123).should    eq("                +123")
    ("%+20d" % -123).should   eq("                -123")
    ("% 20d" % 123).should    eq("                 123")
    ("%020d" % 123).should    eq("00000000000000000123")
    ("%+020d" % 123).should   eq("+0000000000000000123")
    ("% 020d" % 123).should   eq(" 0000000000000000123")
    ("%-d" % 123).should      eq("123")
    ("%-20d" % 123).should    eq("123                 ")
    ("%-+20d" % 123).should   eq("+123                ")
    ("%-+20d" % -123).should  eq("-123                ")
    ("%- 20d" % 123).should   eq(" 123                ")
    ("%s" % 'a').should       eq("a")
    ("%-s" % 'a').should      eq("a")
    ("%20s" % 'a').should     eq("                   a")
    ("%20s" % 'a').should     eq("                   a")
    ("%-20s" % 'a').should    eq("a                   ")

    ("%%%d" % 1).should eq("%1")
    ("foo %d bar %s baz %d goo" % [1, "hello", 2]).should eq("foo 1 bar hello baz 2 goo")
  end

  it "escapes chars" do
    "\t"[0].should eq('\t')
    "\n"[0].should eq('\n')
    "\v"[0].should eq('\v')
    "\f"[0].should eq('\f')
    "\r"[0].should eq('\r')
    "\e"[0].should eq('\e')
    "\""[0].should eq('"')
    "\\"[0].should eq('\\')
  end

  it "escapes with octal" do
    "\3"[0].ord.should eq(3)
    "\23"[0].ord.should eq((2 * 8) + 3)
    "\123"[0].ord.should eq((1 * 8 * 8) + (2 * 8) + 3)
    "\033"[0].ord.should eq((3 * 8) + 3)
    "\033a"[1].should eq('a')
  end

  it "escapes with unicode" do
    "\u{12}".codepoint_at(0).should eq(1 * 16 + 2)
    "\u{A}".codepoint_at(0).should eq(10)
    "\u{AB}".codepoint_at(0).should eq(10 * 16 + 11)
    "\u{AB}1".codepoint_at(1).should eq('1'.ord)
  end

  it "does char_at" do
    "いただきます".char_at(2).should eq('だ')
  end

  it "does byte_at" do
    "hello".byte_at(1).should eq('e'.ord)
  end

  it "does chars" do
    "ぜんぶ".chars.should eq(['ぜ', 'ん', 'ぶ'])
  end

  it "allows creating a string with zeros" do
    p = Pointer(UInt8).malloc(3)
    p[0] = 'a'.ord.to_u8
    p[1] = '\0'.ord.to_u8
    p[2] = 'b'.ord.to_u8
    s = String.new(p, 3)
    s[0].should eq('a')
    s[1].should eq('\0')
    s[2].should eq('b')
    s.bytesize.should eq(3)
  end

  it "tr" do
    "bla".tr("a", "h").should eq("blh")
    "bla".tr("a", "⊙").should eq("bl⊙")
    "bl⊙a".tr("⊙", "a").should eq("blaa")
    "bl⊙a".tr("⊙", "ⓧ").should eq("blⓧa")
    "bl⊙a⊙asdfd⊙dsfsdf⊙⊙⊙".tr("a⊙", "ⓧt").should eq("bltⓧtⓧsdfdtdsfsdfttt")
    "hello".tr("aeiou", "*").should eq("h*ll*")
    "hello".tr("el", "ip").should eq("hippo")
    "Lisp".tr("Lisp", "Crys").should eq("Crys")
    "hello".tr("helo", "1212").should eq("12112")
    "this".tr("this", "ⓧ").should eq("ⓧⓧⓧⓧ")
    "über".tr("ü","u").should eq("uber")
  end

  describe "compare" do
    it "compares with == when same string" do
      "foo".should eq("foo")
    end

    it "compares with == when different strings same contents" do
      s1 = "foo#{1}"
      s2 = "foo#{1}"
      s1.should eq(s2)
    end

    it "compares with == when different contents" do
      s1 = "foo#{1}"
      s2 = "foo#{2}"
      s1.should_not eq(s2)
    end

    it "sorts strings" do
      s1 = "foo1"
      s2 = "foo"
      s3 = "bar"
      [s1, s2, s3].sort.should eq(["bar", "foo", "foo1"])
    end
  end

  it "does underscore" do
    "Foo".underscore.should eq("foo")
    "FooBar".underscore.should eq("foo_bar")
  end

  it "does camelcase" do
    "foo".camelcase.should eq("Foo")
    "foo_bar".camelcase.should eq("FooBar")
  end
end
