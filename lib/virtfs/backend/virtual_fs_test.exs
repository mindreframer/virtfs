defmodule Virtfs.Backend.VirtualFSTest do
  use ExUnit.Case
  use Mneme, action: :accept, default_pattern: :last

  alias Virtfs.Backend.VirtualFS

  describe "write" do
    test "works" do
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
          "/first" => %Virtfs.File{kind: :dir, path: "/first"},
          "/first/second" => %Virtfs.File{kind: :dir, path: "/first/second"},
          "/first/second/path.txt" => %Virtfs.File{
            content: "path",
            path: "/first/second/path.txt"
          },
          "/first/second/path2.txt" => %Virtfs.File{
            content: "path2",
            path: "/first/second/path2.txt"
          }
        } <- fs.files
      )
    end
  end

  describe "read" do
    test "works - simple" do
      fs = Virtfs.init()
      {:ok, fs} = VirtualFS.write(fs, "/path.txt", "path")
      {:ok, fs} = VirtualFS.write(fs, "/path2.txt", "path2")

      auto_assert({:ok, "path"} <- VirtualFS.read(fs, "/path.txt"))
      auto_assert({:ok, "path2"} <- VirtualFS.read(fs, "/path2.txt"))
    end

    test "works - nested" do
      fs = Virtfs.init()

      {:ok, fs} = VirtualFS.cd(fs, "first/second")
      {:ok, fs} = VirtualFS.write(fs, "path.txt", "path")
      {:ok, fs} = VirtualFS.write(fs, "path2.txt", "path2")

      auto_assert({:ok, "path"} <- VirtualFS.read(fs, "path.txt"))
      auto_assert({:ok, "path"} <- VirtualFS.read(fs, "/first/second/path.txt"))
      auto_assert({:error, :not_found} <- VirtualFS.read(fs, "/path.txt"))
    end
  end

  describe "rm" do
    test "works only for files" do
      fs = Virtfs.init()
      {:ok, fs} = VirtualFS.cd(fs, "first/second")
      {:ok, fs} = VirtualFS.write(fs, "path.txt", "path")
      {:ok, fs} = VirtualFS.write(fs, "path2.txt", "path2")
      {:ok, fs} = VirtualFS.rm(fs, "path.txt")

      auto_assert(
        %{
          "/first" => %Virtfs.File{kind: :dir, path: "/first"},
          "/first/second" => %Virtfs.File{kind: :dir, path: "/first/second"},
          "/first/second/path2.txt" => %Virtfs.File{
            content: "path2",
            path: "/first/second/path2.txt"
          }
        } <- fs.files
      )
    end

    test "does not work for folders" do
      fs = Virtfs.init()
      {:ok, fs} = VirtualFS.cd(fs, "first/second")
      {:ok, fs} = VirtualFS.write(fs, "path.txt", "path")
      {:ok, fs} = VirtualFS.write(fs, "path2.txt", "path2")
      {:ok, fs} = VirtualFS.rm(fs, "/first")

      auto_assert({:ok, ["/first/second"]} <- VirtualFS.ls(fs, "/first"))
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

  describe "ls" do
    test "works for the current folder" do
      fs = Virtfs.init()
      {:ok, fs} = VirtualFS.cd(fs, "/first/second/third")
      {:ok, fs} = VirtualFS.mkdir_p(fs, "my/nested/folder")
      {:ok, fs} = VirtualFS.mkdir_p(fs, "my/nested/folder2")
      {:ok, fs} = VirtualFS.mkdir_p(fs, "my/nested/folder3")
      {:ok, fs} = VirtualFS.write(fs, "my/nested/folder/file.txt", "content")

      auto_assert({:ok, ["/first/second/third/my/nested"]} <- VirtualFS.ls(fs, "my"))

      auto_assert(
        {:ok,
         [
           "/first/second/third/my/nested/folder",
           "/first/second/third/my/nested/folder2",
           "/first/second/third/my/nested/folder3"
         ]} <- VirtualFS.ls(fs, "my/nested")
      )

      auto_assert(
        {:ok, ["/first/second/third/my/nested/folder/file.txt"]} <-
          VirtualFS.ls(fs, "my/nested/folder")
      )
    end

    test "works for top folder" do
      fs = Virtfs.init()
      {:ok, fs} = VirtualFS.write(fs, "file1.txt", "content")
      {:ok, fs} = VirtualFS.write(fs, "file2.txt", "content")

      auto_assert({:ok, ["/", "/file1.txt", "/file2.txt"]} <- VirtualFS.ls(fs, "/"))
    end
  end

  describe "tree" do
    test "returns recursivelly files below given path" do
      fs = Virtfs.init()
      {:ok, fs} = VirtualFS.cd(fs, "/first/second/third")
      {:ok, fs} = VirtualFS.mkdir_p(fs, "my/nested/folder")
      {:ok, fs} = VirtualFS.mkdir_p(fs, "my/nested/folder2")
      {:ok, fs} = VirtualFS.mkdir_p(fs, "my/nested/folder3")
      {:ok, fs} = VirtualFS.write(fs, "my/nested/folder/file.txt", "content")

      auto_assert(
        {:ok,
         [
           "/first",
           "/first/second",
           "/first/second/third",
           "/first/second/third/my",
           "/first/second/third/my/nested",
           "/first/second/third/my/nested/folder",
           "/first/second/third/my/nested/folder/file.txt",
           "/first/second/third/my/nested/folder2",
           "/first/second/third/my/nested/folder3"
         ]} <- VirtualFS.tree(fs, "/first")
      )

      auto_assert(
        {:ok,
         [
           "/first/second/third/my/nested",
           "/first/second/third/my/nested/folder",
           "/first/second/third/my/nested/folder/file.txt",
           "/first/second/third/my/nested/folder2",
           "/first/second/third/my/nested/folder3"
         ]} <- VirtualFS.tree(fs, "my/nested")
      )
    end
  end

  describe "mkdir_p" do
    test "creates full hierarchy of folders" do
      fs = Virtfs.init()
      {:ok, fs} = VirtualFS.cd(fs, "/first/second/third")
      {:ok, fs} = VirtualFS.mkdir_p(fs, "my/nested/folder")

      auto_assert(
        %{
          "/first" => %Virtfs.File{kind: :dir, path: "/first"},
          "/first/second" => %Virtfs.File{kind: :dir, path: "/first/second"},
          "/first/second/third" => %Virtfs.File{kind: :dir, path: "/first/second/third"},
          "/first/second/third/my" => %Virtfs.File{kind: :dir, path: "/first/second/third/my"},
          "/first/second/third/my/nested" => %Virtfs.File{
            kind: :dir,
            path: "/first/second/third/my/nested"
          },
          "/first/second/third/my/nested/folder" => %Virtfs.File{
            kind: :dir,
            path: "/first/second/third/my/nested/folder"
          }
        } <- fs.files
      )
    end

    test "does not duplicate folders" do
      fs = Virtfs.init()
      {:ok, fs} = VirtualFS.cd(fs, "/first/")
      {:ok, fs} = VirtualFS.mkdir_p(fs, "my/nested/folder")
      {:ok, fs} = VirtualFS.mkdir_p(fs, "my/nested/folder")
      {:ok, fs} = VirtualFS.cd(fs, "..")
      {:ok, fs} = VirtualFS.mkdir_p(fs, "first/my/nested/folder")

      auto_assert(
        %{
          "/first" => %Virtfs.File{kind: :dir, path: "/first"},
          "/first/my" => %Virtfs.File{kind: :dir, path: "/first/my"},
          "/first/my/nested" => %Virtfs.File{kind: :dir, path: "/first/my/nested"},
          "/first/my/nested/folder" => %Virtfs.File{kind: :dir, path: "/first/my/nested/folder"}
        } <- fs.files
      )
    end
  end

  describe "rename" do
    test "works with existing files" do
      fs = Virtfs.init()
      {:ok, fs} = VirtualFS.cd(fs, "/first/second/third")
      {:ok, fs} = VirtualFS.mkdir_p(fs, "my/nested/folder")
      {:ok, fs} = VirtualFS.write(fs, "file1.txt", "content")
      {:ok, fs} = VirtualFS.cd(fs, "/")

      auto_assert(
        {:ok,
         [
           "/",
           "/first",
           "/first/second",
           "/first/second/third",
           "/first/second/third/file1.txt",
           "/first/second/third/my",
           "/first/second/third/my/nested",
           "/first/second/third/my/nested/folder"
         ]} <- VirtualFS.tree(fs, "/")
      )

      {:ok, fs} = VirtualFS.rename(fs, "/first/second/third/file1.txt", "/first/second/file1.txt")

      auto_assert(
        {:ok,
         [
           "/first/second",
           "/first/second/file1.txt",
           "/first/second/third",
           "/first/second/third/my",
           "/first/second/third/my/nested",
           "/first/second/third/my/nested/folder"
         ]} <- VirtualFS.tree(fs, "/first/second")
      )
    end

    test "does not work with missing files - FIXME silent failure" do
      fs = Virtfs.init()
      {:ok, fs} = VirtualFS.write(fs, "file1.txt", "content")
      {:ok, fs} = VirtualFS.rename(fs, "missing.txt", "file1.txt")
      auto_assert({:ok, ["/", "/file1.txt"]} <- VirtualFS.tree(fs, "/"))
    end
  end

  describe "cp" do
    test "works for files" do
      fs = Virtfs.init()
      {:ok, fs} = VirtualFS.write(fs, "file1.txt", "content")
      {:ok, fs} = VirtualFS.cp(fs, "file1.txt", "file2.txt")

      auto_assert({:ok, ["/", "/file1.txt", "/file2.txt"]} <- VirtualFS.ls(fs, "/"))
      auto_assert({:ok, "content"} <- VirtualFS.read(fs, "file2.txt"))
    end

    test "does not work for folders" do
      fs = Virtfs.init()
      {:ok, fs} = VirtualFS.write(fs, "folder/file1.txt", "content")
      {:ok, fs} = VirtualFS.cp(fs, "folder", "folder2")

      auto_assert({:ok, ["/", "/folder"]} <- VirtualFS.ls(fs, "/"))
      auto_assert({:error, :not_found} <- VirtualFS.ls(fs, "/folder2"))
    end
  end
end
