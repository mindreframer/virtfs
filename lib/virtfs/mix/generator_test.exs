Code.require_file("./test_helper.exs", __DIR__)

defmodule Mix.GeneratorTest do
  use ExUnit.Case
  import Virtfs.Mix.Generator

  embed_text(:foo, "foo")
  embed_text(:self, from_file: __ENV__.file)
  embed_template(:bar, "<%= @a + @b %>")

  def in_tmp(which, function) do
    {:ok, fs} = Virtfs.start_link()
    Virtfs.mkdir_p!(fs, which)
    Virtfs.cd!(fs, which)
    function.(fs)
  end

  def tmp_path do
    Path.expand("../tmp", __DIR__)
  end

  def tmp_path(extension) do
    Path.join(tmp_path(), remove_colons(extension))
  end

  defp remove_colons(term) do
    term
    |> to_string()
    |> String.replace(":", "")
  end

  describe "embed_text/2" do
    test "with contents" do
      assert foo_text() == "foo"
    end

    test "from file" do
      assert self_text() =~ "import Mix.Generator"
    end
  end

  test "embed template" do
    assert bar_template(a: 1, b: 2) == "3"
  end

  describe "overwrite?/1" do
    test "without conflict" do
      in_tmp("overwrite", fn fs ->
        assert overwrite?(fs, "foo")
        refute_received {:mix_shell, :yes?, ["foo already exists, overwrite?"]}
      end)
    end

    test "with conflict returning true" do
      in_tmp("overwrite", fn fs ->
        Virtfs.write!(fs, "foo", "HELLO")
        send(self(), {:mix_shell_input, :yes?, true})

        assert overwrite?(fs, "foo")
        assert_received {:mix_shell, :yes?, ["foo already exists, overwrite?"]}
      end)
    end

    test "with conflict returning false" do
      in_tmp("overwrite", fn fs ->
        Virtfs.write!(fs, "foo", "HELLO")
        send(self(), {:mix_shell_input, :yes?, false})

        refute overwrite?(fs, "foo")
        assert_received {:mix_shell, :yes?, ["foo already exists, overwrite?"]}
      end)
    end
  end

  describe "overwrite?/2" do
    test "without conflict" do
      in_tmp("overwrite", fn fs ->
        assert overwrite?(fs, "foo", "HELLO")
        refute_received {:mix_shell, :yes?, ["foo already exists, overwrite?"]}
      end)
    end

    test "with same contents" do
      in_tmp("overwrite", fn fs ->
        Virtfs.write!(fs, "foo", "HELLO")
        refute overwrite?(fs, "foo", "HELLO")
        refute_received {:mix_shell, :yes?, ["foo already exists, overwrite?"]}
      end)
    end

    test "with conflict returning true" do
      in_tmp("overwrite", fn fs ->
        Virtfs.write!(fs, "foo", "HELLO")
        send(self(), {:mix_shell_input, :yes?, true})

        assert overwrite?(fs, "foo", "WORLD")
        assert_received {:mix_shell, :yes?, ["foo already exists, overwrite?"]}
      end)
    end

    test "with conflict returning false" do
      in_tmp("overwrite", fn fs ->
        Virtfs.write!(fs, "foo", "HELLO")
        send(self(), {:mix_shell_input, :yes?, false})

        refute overwrite?(fs, "foo", "WORLD")
        assert_received {:mix_shell, :yes?, ["foo already exists, overwrite?"]}
      end)
    end
  end

  describe "create_file/3" do
    test "creates file" do
      in_tmp("create_file", fn fs ->
        create_file(fs, "foo", "HELLO")
        assert Virtfs.read!(fs, "foo") == "HELLO"
        assert_received {:mix_shell, :info, ["* creating foo"]}
      end)
    end

    test "with quiet" do
      in_tmp("create_file", fn fs ->
        create_file(fs, "foo", "HELLO", quiet: true)
        assert Virtfs.read!(fs, "foo") == "HELLO"
        refute_received {:mix_shell, :info, ["* creating foo"]}
      end)
    end

    test "with force" do
      in_tmp("create_file", fn fs ->
        Virtfs.write!(fs, "foo", "HELLO")
        create_file(fs, "foo", "WORLD", force: true)
        assert Virtfs.read!(fs, "foo") == "WORLD"

        refute_received {:mix_shell, :yes?, ["foo already exists, overwrite?"]}
        assert_received {:mix_shell, :info, ["* creating foo"]}
      end)
    end

    test "with same contents" do
      in_tmp("create_file", fn fs ->
        Virtfs.write!(fs, "foo", "HELLO")
        create_file(fs, "foo", "HELLO")
        assert Virtfs.read!(fs, "foo") == "HELLO"
        refute_received {:mix_shell, :yes?, ["foo already exists, overwrite?"]}
      end)
    end

    test "with conflict returning true" do
      in_tmp("create_file", fn fs ->
        Virtfs.write!(fs, "foo", "HELLO")
        send(self(), {:mix_shell_input, :yes?, true})

        create_file(fs, "foo", "WORLD")
        assert Virtfs.read!(fs, "foo") == "WORLD"
        assert_received {:mix_shell, :yes?, ["foo already exists, overwrite?"]}
      end)
    end

    test "with conflict returning false" do
      in_tmp("create_file", fn fs ->
        Virtfs.write!(fs, "foo", "HELLO")
        send(self(), {:mix_shell_input, :yes?, false})

        create_file(fs, "foo", "WORLD")
        assert Virtfs.read!(fs, "foo") == "HELLO"
        assert_received {:mix_shell, :yes?, ["foo already exists, overwrite?"]}
      end)
    end
  end

  describe "copy_file/3" do
    test "copies file" do
      in_tmp("copy_file", fn fs ->
        Virtfs.write!(fs, "bar", "HELLO")
        copy_file(fs, "bar", "foo")
        assert Virtfs.read!(fs, "foo") =~ ~s[HELLO]
        assert_received {:mix_shell, :info, ["* creating foo"]}
      end)
    end

    test "with quiet" do
      in_tmp("copy_file", fn fs ->
        Virtfs.write!(fs, "bar", "HELLO")
        copy_file(fs, "bar", "foo", quiet: true)
        assert Virtfs.read!(fs, "foo") =~ ~s[HELLO]
        refute_received {:mix_shell, :info, ["* creating foo"]}
      end)
    end

    test "with force" do
      in_tmp("copy_file", fn fs ->
        Virtfs.write!(fs, "foo", "HELLO")
        Virtfs.write!(fs, "foo-to-copy", "HELLO--")
        copy_file(fs, "foo-to-copy", "foo", force: true)
        assert Virtfs.read!(fs, "foo") =~ ~s[HELLO--]

        refute_received {:mix_shell, :yes?, ["foo already exists, overwrite?"]}
        assert_received {:mix_shell, :info, ["* creating foo"]}
      end)
    end

    test "with same contents" do
      in_tmp("copy_file", fn fs ->
        Virtfs.write!(fs, "bar", "HELLO")
        copy_file(fs, "bar", "foo")
        copy_file(fs, "bar", "foo")
        refute_received {:mix_shell, :yes?, ["foo already exists, overwrite?"]}
      end)
    end

    test "with conflict returning true" do
      in_tmp("copy_file", fn fs ->
        Virtfs.write!(fs, "foo", "HELLO")
        Virtfs.write!(fs, "bar", "describe")
        send(self(), {:mix_shell_input, :yes?, true})

        copy_file(fs, "bar", "foo")
        assert Virtfs.read!(fs, "foo") =~ ~s[describe]
        assert_received {:mix_shell, :yes?, ["foo already exists, overwrite?"]}
      end)
    end

    test "with conflict returning false" do
      in_tmp("copy_file", fn fs ->
        Virtfs.write!(fs, "foo", "HELLO")
        Virtfs.write!(fs, "bar", "BAR")

        send(self(), {:mix_shell_input, :yes?, false})
        copy_file(fs, "bar", "foo")
        assert Virtfs.read!(fs, "foo") == "HELLO"
        assert_received {:mix_shell, :yes?, ["foo already exists, overwrite?"]}
      end)
    end
  end

  describe "copy_template/4" do
    test "copies template" do
      in_tmp("copy_template", fn fs ->
        copy_template(fs, __ENV__.file, "foo", a: 1, b: 2)
        assert Virtfs.read!(fs, "foo") =~ ~s[embed_template(:bar, "3")]
        assert_received {:mix_shell, :info, ["* creating foo"]}
      end)
    end

    test "with quiet" do
      in_tmp("copy_template", fn fs ->
        copy_template(fs, __ENV__.file, "foo", [a: 1, b: 2], quiet: true)
        assert Virtfs.read!(fs, "foo") =~ ~s[embed_template(:bar, "3")]
        refute_received {:mix_shell, :info, ["* creating foo"]}
      end)
    end

    test "with force" do
      in_tmp("copy_template", fn fs ->
        Virtfs.write!(fs, "foo", "HELLO")
        copy_template(fs, __ENV__.file, "foo", [a: 1, b: 2], force: true)
        assert Virtfs.read!(fs, "foo") =~ ~s[embed_template(:bar, "3")]

        refute_received {:mix_shell, :yes?, ["foo already exists, overwrite?"]}
        assert_received {:mix_shell, :info, ["* creating foo"]}
      end)
    end

    test "with same contents" do
      in_tmp("copy_template", fn fs ->
        copy_template(fs, __ENV__.file, "foo", a: 1, b: 2)
        copy_template(fs, __ENV__.file, "foo", a: 1, b: 2)
        refute_received {:mix_shell, :yes?, ["foo already exists, overwrite?"]}
      end)
    end

    test "with conflict returning true" do
      in_tmp("copy_template", fn fs ->
        Virtfs.write!(fs, "foo", "HELLO")
        send(self(), {:mix_shell_input, :yes?, true})

        copy_template(fs, __ENV__.file, "foo", a: 1, b: 2)
        assert Virtfs.read!(fs, "foo") =~ ~s[embed_template(:bar, "3")]
        assert_received {:mix_shell, :yes?, ["foo already exists, overwrite?"]}
      end)
    end

    test "with conflict returning false" do
      in_tmp("copy_template", fn fs ->
        Virtfs.write!(fs, "foo", "HELLO")
        send(self(), {:mix_shell_input, :yes?, false})

        copy_template(fs, __ENV__.file, "foo", a: 1, b: 2)
        assert Virtfs.read!(fs, "foo") == "HELLO"
        assert_received {:mix_shell, :yes?, ["foo already exists, overwrite?"]}
      end)
    end
  end
end
