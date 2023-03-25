defmodule Virtfs.Backend.VirtualFSTest do
  use ExUnit.Case
  use Mneme, action: :accept, default_pattern: :last

  alias Virtfs.Backend.VirtualFS

  test "1" do
    fs = Virtfs.init()
    {:ok, fs} = VirtualFS.write(fs, "/path.txt", "path")
    {:ok, fs} = VirtualFS.write(fs, "/path2.txt", "path2")

    auto_assert(
      %{
        "/path.txt" => %Virtfs.File{content: "path", path: "/path.txt"},
        "/path2.txt" => %Virtfs.File{content: "path2", path: "/path2.txt"}
      } <- fs.files
    )
  end

  test "cwd is considered" do
    fs = Virtfs.init()
    {:ok, fs} = VirtualFS.cd(fs, "first/second")
    {:ok, fs} = VirtualFS.write(fs, "path.txt", "path")
    {:ok, fs} = VirtualFS.write(fs, "path2.txt", "path2")

    auto_assert(
      %{
        "/first/second/path.txt" => %Virtfs.File{content: "path", path: "/first/second/path.txt"},
        "/first/second/path2.txt" => %Virtfs.File{
          content: "path2",
          path: "/first/second/path2.txt"
        }
      } <- fs.files
    )
  end

  describe "rm" do
    test "works for files" do
      fs = Virtfs.init()
      {:ok, fs} = VirtualFS.cd(fs, "first/second")
      {:ok, fs} = VirtualFS.write(fs, "path.txt", "path")
      {:ok, fs} = VirtualFS.write(fs, "path2.txt", "path2")
      {:ok, fs} = VirtualFS.rm(fs, "path.txt")

      auto_assert(
        %{
          "/first/second/path2.txt" => %Virtfs.File{
            content: "path2",
            path: "/first/second/path2.txt"
          }
        } <- fs.files
      )
    end

    test "works for dirs" do
      #   fs = Virtfs.init()
      #   {:ok, fs} = VirtualFS.cd(fs, "first/second")
      #   {:ok, fs} = VirtualFS.write(fs, "path.txt", "path")
      #   {:ok, fs} = VirtualFS.write(fs, "path2.txt", "path2")
      #   {:ok, fs} = VirtualFS.rm(fs, "path.txt")
      #   {:ok, fs} = VirtualFS.cd(fs, "..")
      #   {:ok, fs} = VirtualFS.cd(fs, "..")

      #   auto_assert(
      #     %{
      #       "/first/second/path2.txt" => %Virtfs.File{
      #         content: "path2",
      #         path: "/first/second/path2.txt"
      #       }
      #     } <- fs.files
      #   )
    end
  end

  describe "cd" do
    test ".. works" do
      fs = Virtfs.init()
      {:ok, fs} = VirtualFS.cd(fs, "first/second")
      auto_assert("/first/second" <- fs.cwd)

      {:ok, fs} = VirtualFS.cd(fs, "..")
      auto_assert("/first" <- fs.cwd)

      {:ok, fs} = VirtualFS.cd(fs, "..")
      auto_assert("/" <- fs.cwd)

      {:ok, fs} = VirtualFS.cd(fs, "..")
      auto_assert("/" <- fs.cwd)
    end

    test ".. with mixed instructions works" do
      fs = Virtfs.init()
      {:ok, fs} = VirtualFS.cd(fs, "/first/second/third")
      auto_assert("/first/second/third" <- fs.cwd)

      {:ok, fs} = VirtualFS.cd(fs, "../fourth")
      auto_assert("/first/second/fourth" <- fs.cwd)

      {:ok, fs} = VirtualFS.cd(fs, "..")
      auto_assert("/first/second" <- fs.cwd)

      {:ok, fs} = VirtualFS.cd(fs, "..")
      auto_assert("/first" <- fs.cwd)
    end
  end

  describe "mkdir_p" do
    test "creates full hierarchy of folders" do
      fs = Virtfs.init()
      {:ok, fs} = VirtualFS.cd(fs, "/first/second/third")
      {:ok, fs} = VirtualFS.mkdir_p(fs, "my/nested/folder")

      auto_assert(
        {:ok,
         [
           "/first",
           "/first/second",
           "/first/second/third",
           "/first/second/third/my",
           "/first/second/third/my/nested",
           "/first/second/third/my/nested/folder"
         ]} <- VirtualFS.ls(fs, "/")
      )
    end
  end
end
