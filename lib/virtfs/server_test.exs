defmodule Virtfs.ServerTest do
  use ExUnit.Case
  use Mneme, action: :accept, default_pattern: :last

  alias Virtfs.Server

  setup :new_fs

  describe "read!" do
    test "write! / read! work", %{fs: fs} do
      auto_assert(:ok <- Server.mkdir_p!(fs, "/a/b/c"))
      auto_assert(:ok <- Server.write(fs, "/a/d/f/file.txt", "my poem/nand more!"))
      auto_assert("my poem/nand more!" <- Server.read!(fs, "/a/d/f/file.txt"))
    end

    test "raises on invalid input", %{fs: fs} do
      assert_raise RuntimeError, "{{:error, :not_found}, {:read!, \"/a\"}}", fn ->
        auto_assert(:ok <- Server.read!(fs, "/a"))
      end
    end
  end

  describe "append" do
    test "simple append works", %{fs: fs} do
      auto_assert(:ok <- Server.mkdir_p!(fs, "/a"))
      auto_assert(:ok <- Server.write(fs, "/a/file.txt", "my poem\nand more!"))
      auto_assert(:ok <- Server.append!(fs, "/a/file.txt", "---more-content"))

      auto_assert(
        """
        my poem
        and more!---more-content\
        """ <- Server.read!(fs, "/a/file.txt")
      )
    end

    test "simple append_line works", %{fs: fs} do
      auto_assert(:ok <- Server.mkdir_p!(fs, "/a"))
      auto_assert(:ok <- Server.write(fs, "/a/file.txt", "my poem\nand more!"))
      auto_assert(:ok <- Server.append_line!(fs, "/a/file.txt", "---more-content"))
      auto_assert(:ok <- Server.append_line!(fs, "/a/file.txt", "---2more-content"))

      auto_assert(
        """
        my poem
        and more!
        ---more-content
        ---2more-content\
        """ <- Server.read!(fs, "/a/file.txt")
      )
    end
  end

  describe "ls!" do
    test "write! / read! work", %{fs: fs} do
      auto_assert(:ok <- Server.mkdir_p!(fs, "/a/b/c"))
      auto_assert(:ok <- Server.write(fs, "/a/b/file.txt", "my poem/nand more!"))
      auto_assert(["/a/b/c", "/a/b/file.txt"] <- Server.ls!(fs, "/a/b"))
    end

    test "raises on invalid input", %{fs: fs} do
      assert_raise RuntimeError, "{{:error, :not_found}, {:ls!, \"/a/--\"}}", fn ->
        auto_assert(:ok <- Server.ls!(fs, "/a/--"))
      end
    end
  end

  describe "rm!" do
    test "works", %{fs: fs} do
      auto_assert(:ok <- Server.mkdir_p!(fs, "/a/b/c"))
      auto_assert(:ok <- Server.write(fs, "/a/b/file.txt", "my poem/nand more!"))
      auto_assert(["/a/b/c", "/a/b/file.txt"] <- Server.ls!(fs, "/a/b"))
      auto_assert(:ok <- Server.rm!(fs, "/a/b/file.txt"))
    end

    test "raises on invalid input", %{fs: fs} do
      assert_raise RuntimeError, "{{:error, :source_not_found}, {:rm!, \"--file--\"}}", fn ->
        auto_assert(:ok <- Server.rm!(fs, "--file--"))
      end
    end
  end

  describe "rename!" do
    test "works", %{fs: fs} do
      auto_assert(:ok <- Server.mkdir_p!(fs, "/a/b/c"))
      auto_assert(:ok <- Server.write(fs, "/a/b/file.txt", "my poem/nand more!"))
      auto_assert(["/a/b/c", "/a/b/file.txt"] <- Server.ls!(fs, "/a/b"))
      auto_assert(:ok <- Server.rename!(fs, "/a/b", "a/new"))
      auto_assert(["/a", "/a/new", "/a/new/c", "/a/new/file.txt"] <- Server.tree!(fs, "/"))
    end

    test "raises on invalid input", %{fs: fs} do
      assert_raise RuntimeError,
                   "{{:error, :source_not_found}, {:rename!, \"/a\", \"/b\"}}",
                   fn ->
                     auto_assert(:ok <- Server.rename!(fs, "/a", "/b"))
                   end
    end
  end

  describe "cp_r!" do
    test "works", %{fs: fs} do
      auto_assert(:ok <- Server.mkdir_p!(fs, "/a/b/c"))
      auto_assert(:ok <- Server.write(fs, "/a/b/file.txt", "my poem/nand more!"))
      auto_assert(["/a/b/c", "/a/b/file.txt"] <- Server.ls!(fs, "/a/b"))
      auto_assert(:ok <- Server.cp_r!(fs, "/a/b", "a/new"))

      auto_assert(
        ["/a", "/a/b", "/a/b/c", "/a/b/file.txt", "/a/new", "/a/new/c", "/a/new/file.txt"] <-
          Server.tree!(fs, "/")
      )

      auto_assert({:ok, "my poem/nand more!"} <- Server.read(fs, "/a/new/file.txt"))
    end

    test "raises on invalid input", %{fs: fs} do
      assert_raise RuntimeError,
                   "{{:error, :source_not_found}, {:cp_r!, \"/a\", \"/b\"}}",
                   fn ->
                     auto_assert(:ok <- Server.cp_r!(fs, "/a", "/b"))
                   end
    end
  end

  describe "mkdir_p!" do
    test "works on valid input", %{fs: fs} do
      auto_assert(:ok <- Server.mkdir_p!(fs, "/a/b/c"))
      auto_assert(:ok <- Server.mkdir_p!(fs, "/a/d/f"))
      auto_assert(["/a/b", "/a/b/c", "/a/d", "/a/d/f"] <- Server.tree!(fs, "/a"))
    end

    test "works on invalid input", %{fs: _fs} do
      # TODO maybe cover input validation later
      # auto_assert(:ok <- Server.mkdir_p!(fs, ))
    end
  end

  defp new_fs(_) do
    {:ok, fs} = Server.start_link()
    {:ok, %{fs: fs}}
  end
end
