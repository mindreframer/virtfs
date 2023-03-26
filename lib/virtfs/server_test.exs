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
      auto_assert(["/a", "/a/b", "/a/new/c", "/a/new/file.txt"] <- Server.tree!(fs, "/"))
    end

    test "raises on invalid input", %{fs: fs} do
      assert_raise RuntimeError,
                   "{{:error, :source_not_found}, {:rename!, \"/a\", \"/b\"}}",
                   fn ->
                     auto_assert(:ok <- Server.rename!(fs, "/a", "/b"))
                   end
    end
  end

  describe "mkdir_p!" do
    test "works on valid input", %{fs: fs} do
      auto_assert(:ok <- Server.mkdir_p!(fs, "/a/b/c"))
      auto_assert(:ok <- Server.mkdir_p!(fs, "/a/d/f"))
      auto_assert(["/a/b", "/a/b/c", "/a/d", "/a/d/f"] <- Server.tree!(fs, "/a"))
    end

    test "works on invalid input", %{fs: fs} do
      # TODO maybe cover input validation later
      # auto_assert(:ok <- Server.mkdir_p!(fs, ))
    end
  end

  defp new_fs(_) do
    {:ok, fs} = Server.start_link()
    {:ok, %{fs: fs}}
  end
end
