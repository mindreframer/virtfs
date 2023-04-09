defmodule Virtfs.PathGlob.MatchHelper do
  alias Virtfs.PathGlob
  @tmpdir "#{__DIR__}/../.tmp"

  import ExUnit.Assertions

  defmacro test_match(path, glob, opts \\ []) do
    quote do
      test "glob '#{unquote(glob)}' matches path '#{unquote(path)}'" do
        within_tmpdir(unquote(path), fn ->
          assert_match(unquote(path), unquote(glob), unquote(opts))
        end)
      end
    end
  end

  defmacro test_no_match(path, glob, opts \\ []) do
    quote do
      test "glob '#{unquote(glob)}' doesn't match path '#{unquote(path)}'" do
        within_tmpdir(unquote(path), fn ->
          refute_match(unquote(path), unquote(glob), unquote(opts))
        end)
      end
    end
  end

  defmacro test_error(path, glob, wildcard_exception) do
    quote do
      test "glob '#{unquote(glob)}' raises an error" do
        assert_error(unquote(path), unquote(glob), unquote(wildcard_exception))
      end
    end
  end

  def assert_match(path, glob, opts \\ []) do
    assert path in Path.wildcard(glob, opts),
           "expected #{wildcard_call(glob, opts)} to include '#{path}'"

    assert PathGlob.match?(glob, path, opts),
           "expected '#{glob}' to match '#{path}'"
  end

  def refute_match(path, glob, opts \\ []) do
    assert path not in Path.wildcard(glob, opts),
           "expected #{wildcard_call(glob, opts)} not to include '#{path}'"

    refute PathGlob.match?(glob, path, opts),
           "expected '#{glob}' not to match '#{path}'"
  end

  defp wildcard_call(glob, opts) do
    "Path.wildcard(#{inspect(glob)}, #{inspect(opts)})"
  end

  def assert_error(path, glob, wildcard_exception) do
    try do
      Path.wildcard(glob) == [path]
    rescue
      exception ->
        # This can be changed to is_exception when we drop Elixir 1.10 support
        assert match?(
                 %{__struct__: ^wildcard_exception, __exception__: true},
                 exception
               )
    else
      _ -> raise "expected an error"
    end

    assert_raise(ArgumentError, fn -> PathGlob.match?(glob, path) end)
  end

  def within_tmpdir(path, fun) do
    tmpdir = Path.join(@tmpdir, Enum.take_random(?a..?z, 10))
    File.mkdir_p!(tmpdir)

    try do
      File.cd!(tmpdir, fn ->
        dir = Path.dirname(path)
        unless dir == ".", do: File.mkdir_p!(dir)
        File.write!(path, "")
        fun.()
      end)
    after
      File.rm_rf!(tmpdir)
    end
  end
end

defmodule Virtfs.PathGlobTest do
  use ExUnit.Case, async: true
  doctest Virtfs.PathGlob

  alias Virtfs.PathGlob
  import Virtfs.PathGlob.MatchHelper
  require Virtfs.PathGlob.MatchHelper

  # See
  # https://github.com/erlang/otp/blob/master/lib/stdlib/test/filelib_SUITE.erl
  # for the patterns that :filelib.wildcard/2 is tested with (which is used to
  # implement Elixir's Path.wildcard/2).
  #
  # See
  # https://github.com/elixir-lang/elixir/blob/master/lib/elixir/test/elixir/path_test.exs
  # for the patterns that Path.wildcard/2 is test with.

  describe "literal characters" do
    test_match("foo", "foo")
    test_no_match("foo", "bar")
    test_no_match("foo", "fo")
    test_no_match("foo", "FOO")
    test_no_match(~S(fo\o), ~S(fo\o))
    test_no_match(~S(fo\o), ~S(fo\\o))
    test_match("?q", ~S(\?q))
    test_match("fo{o", ~S(fo\{o))
    test_error("foo", "", MatchError)
    test_match("héllò", "héllò")
  end

  describe "? pattern" do
    test_match("foo", "?oo")
    test_match("foo", "f?o")
    test_match("foo", "f??")
    test_match("foo", "???")
    test_no_match("foo/bar", "foo?bar")
    test_no_match("foo", "foo?")
    test_no_match("foo", "f?oo")
  end

  describe "* pattern" do
    test_match("foo", "*")
    test_match("foo", "f*")
    test_match("foo", "fo*")
    test_match("foo", "foo*")
    test_match("foo", "*foo")
    test_match("foo.ex", "*")
    test_match("foo.ex", "f*")
    test_match("foo.ex", "foo*")
    test_match("foo.ex", "foo.*")
    test_match("foo.ex", "*.ex")
    test_match("foo.ex", "*ex")
    test_match("foo/bar", "foo/*")
    test_match("foo/bar", "foo/b*")
    test_match("foo/bar", "foo/ba*")
    test_match("foo/bar", "foo/bar*")
    test_match("foo/bar", "foo/*bar")
    test_match("foo/bar", "*/bar")
    test_match("foo/bar", "*/*")
    test_match("foo/bar.ex", "foo/*.ex")
    test_match("foo/bar.ex", "foo/*")
    test_no_match("foo", "b*")
    test_no_match("foo/bar", "foo/f*")
    test_no_match("foo/bar", "*ar")
    test_no_match("foo/bar", "baz/*")
  end

  describe "** pattern" do
    test_match("foo", "**")
    test_match("foo", "**o")
    test_match("foo", "**/foo")
    test_match("foo", "**//foo")
    test_match("foo.ex", "**")
    test_match("foo.ex", "**o.ex")
    test_match("foo.ex", "**/foo.ex")
    test_match("foo.ex", "**//foo.ex")
    test_match("foo/bar", "**")
    test_match("foo/bar", "**/bar")
    test_match("foo/bar", "foo/**")
    test_match("foo/bar.ex", "**")
    test_match("foo/bar.ex", "**/bar.ex")
    test_match("foo/bar.ex", "foo/**")
    test_match("foo/bar.ex", "foo/**.ex")
    test_match("foo/bar/baz", "**")
    test_match("foo/bar/baz", "**/baz")
    test_match("foo/bar/baz.ex", "**")
    test_match("foo/bar/baz.ex", "**/baz.ex")
    test_match("foo/bar/baz.ex", "**/bar/**")
    test_match("foo/bar/baz.ex", "**/bar/**.ex")
    test_no_match("foo/bar", "**bar")
    test_no_match("foo/bar", "foo**")
    test_no_match("foo/bar.ex", "**bar.ex")
    test_no_match("foo/bar/baz", "**baz")
    test_no_match("foo/bar/baz.ex", "**baz.ex")
    test_no_match("foo/bar/baz.ex", "**/baz/**")
    test_no_match("foo/bar/baz.ex", "**/baz/**.ex")
  end

  describe "{} pattern" do
    test_match("foo", "{foo}")
    test_match("foo", "{foo,bar}")
    test_match("foo", "{fo,ba}o")
    test_match("foo", "{*o}")
    test_match("foo", "{*o,*a}")
    test_match("foo", "{f*,a*}")
    test_no_match("foo", "{bar}")
    test_no_match("foo", "{bar,baz}")
    test_no_match("foo", "{b}oo")
    test_error("fo{o", "fo{o", ErlangError)
    test_error("fo{o{o}o}", "fo{o{o}o}", CaseClauseError)
    test_match("fo}o", "fo}o")
    test_match("fo}o", "fo}{o}")
    test_match("fo}o", "{f}o}o")
    test_match("fo,o", "fo,o")
    test_match("fo,o", "fo,{o}")
    test_match("abcdef", "a*{def,}")
    test_match("abcdef", "a*{,def}")
    test_match("{abc}", ~S(\{a*))
    test_match("{abc}", ~S(\{abc}))
    test_match("@a,b", ~S(@{a\,b,c}))
    test_match("@c", ~S(@{a\,b,c}))
    test_match("fo[o", ~S({fo\[o}))
    test_match("fo[o", ~S({fo[o}))
  end

  describe "[] pattern" do
    test_match("foo", "f[o]o")
    test_match("foo", "f[ao]o")
    test_match("foo", "f[a-z]o")
    test_match("foo", "f[o,a]o")
    test_no_match("foo", "f[a]o")
    test_no_match("foo", "f[a-d]o")
    test_no_match("foo", "f[a,b]o")
    test_no_match("foo", "foo[]")
    test_match("fo,o", "fo,o")
    test_match("fo,o", "fo,[o]")
    test_match("fo[o", "fo[o")
    test_match("fo]o", "fo]o")
    test_match("foo123", "foo[1]23")
    test_match("foo123", "foo[1-9]23")
    test_match("foo123", "foo[1-39]23")
    test_match("foo923", "foo[1-39]23")
    test_no_match("foo123", "foo[12]3")
    test_no_match("foo123", "foo[1-12]3")
    test_no_match("foo123", "foo[1-123]")
    test_match("a-", "a-")
    test_match("a-", "a[-]")
    test_match("a-", "a[A-C-]")
    test_match("a-", "a[][A-C-]")
    test_match("a[", "a[")
    test_match("a[", "a[[]")
    test_match("a[", "a[a[]")
    test_match("a[", "a[[a]")
    test_match("a[", "a[a[b]")
    test_match("a]", "a]")
    test_match("a]", "a[]a]")
    test_match("a]", "a[]]")
    test_no_match("a]", "a[b,]a]")
    test_no_match("a]", "a[a-z]]")
    test_no_match("a]", "a[a]b]")
    test_no_match("a]", "a[a]]")
    test_match("---", ~S([a\-z]*))
    test_match("abc", ~S([a\-z]*))
    test_match("z--", ~S([a\-z]*))
    test_match("fo{o", ~S(fo[{]o))
    test_match("fo{o", ~S(fo[\{]o))
    test_no_match("fo\o", ~S(fo[\\{]o))
    test_no_match("fo\o", ~S(fo[\{]o))
    test_no_match(~S(\a), ~S([a\-z]*))
  end

  describe "combinations" do
    test_match("foo/bar", "{foo,baz}/*")
    test_match("foo/bar", "**/*")
    test_match("foo/bar/baz", "**/*")
  end

  describe "match_dot: true" do
    test_match(".foo", "*", match_dot: true)
    test_match(".foo", "?foo", match_dot: true)
    test_match(".foo", "**", match_dot: true)
    test_match("foo/.bar", "foo/*", match_dot: true)
    test_match("foo/.bar", "foo/?bar", match_dot: true)
    test_match("foo/.bar", "**", match_dot: true)
    test_match("foo/.bar", "foo/**", match_dot: true)
    test_match("foo/.bar", "**/.bar", match_dot: true)
    test_no_match("foo/.bar", "foo?.bar", match_dot: true)
    test_match("foo/.bar/baz", "foo/*/baz", match_dot: true)
    test_match("foo/.bar/baz", "foo/?bar/baz", match_dot: true)
    test_match("foo/.bar/baz", "**/baz", match_dot: true)
    test_match("foo/.bar/baz", "foo/**/baz", match_dot: true)
  end

  describe "match_dot: false" do
    # Explicit test for default option value
    test_no_match("foo/.foo", "foo/*")

    test_no_match(".foo", "*", match_dot: false)
    test_no_match(".foo", "?foo", match_dot: false)
    test_no_match("foo/.bar", "foo/*", match_dot: false)
    test_no_match("foo/.bar", "foo/?bar", match_dot: false)
    test_match(".foo", ".foo", match_dot: false)
    test_no_match("foo/.foo", "**/.foo", match_dot: false)
    test_no_match("foo/.bar/baz", "foo/*/baz", match_dot: false)
    test_no_match("foo/.bar/baz", "foo/?bar/baz", match_dot: false)
    test_no_match("foo/.bar/baz", "**/baz", match_dot: false)
    test_no_match("foo/.bar/baz", "foo/**/baz", match_dot: false)
  end

  describe "directory traversal" do
    test ".. pattern" do
      within_tmpdir("foo/bar/baz", fn ->
        assert_match("foo/bar/..", "foo/bar/..")
        assert_match("foo/bar/..", "foo/bar/../")
        assert_match("foo/bar/..", "foo/bar/..//")
        assert_match("foo/bar/../bar", "foo/bar/../bar")
      end)
    end

    test ". pattern" do
      within_tmpdir("foo/bar/baz", fn ->
        assert_match(".", ".")
        assert_match(".", "./.")
        assert_match(".", ".//.")
      end)
    end

    test "combining . and .." do
      within_tmpdir("foo/bar/baz", fn ->
        assert_match("foo/bar/../.", "foo/bar/../.")
        assert_match("foo/bar/../.", "foo/bar/..//.")
        assert_match("foo/bar", "foo/./bar")
        assert_match("foo/bar/.", "foo/./bar/.")
      end)
    end

    test "** pattern" do
      within_tmpdir("foo/bar/baz", fn ->
        assert "foo/bar/../bar" in Path.wildcard("foo/bar/../*")
        assert PathGlob.match?("foo/bar/../*", "foo/bar/../bar")
      end)
    end
  end

  describe "absolute paths" do
    defp absolute(path) do
      Path.join(File.cwd!(), path)
    end

    test "basic" do
      within_tmpdir("foo/bar", fn ->
        assert_match(absolute("foo/bar"), absolute("foo/bar"))
        assert_match(absolute("foo/bar"), absolute("foo/*"))
        assert_match(absolute("foo/bar"), absolute("*/bar"))
      end)
    end

    # Testing this the normal way would cause us to traverse the entire
    # filesystem
    test "double star" do
      assert PathGlob.match?("/**/bar", absolute("foo/bar"))
      assert PathGlob.match?("/**/foo", absolute("foo"))
      refute PathGlob.match?("/**/foo", absolute("foo/bar"))
    end
  end

  test "compile/1" do
    regex = PathGlob.compile("f[o]o")
    assert String.match?("foo", regex)
  end
end
