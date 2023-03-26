defmodule Virtfs.BackendTest do
  use ExUnit.Case
  use Mneme, action: :accept, default_pattern: :last

  alias Virtfs.Backend
  alias Virtfs.Util

  describe "write" do
    test "works" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.write(fs, "/path.txt", "path")
      {fs, :ok} = Backend.write(fs, "/path2.txt", "path2")

      auto_assert(
        %{
          "/path.txt" => %Virtfs.File{content: "path", path: "/path.txt"},
          "/path2.txt" => %Virtfs.File{content: "path2", path: "/path2.txt"}
        } <- fs.files
      )
    end

    test "cwd is considered" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.cd(fs, "a/b")
      {fs, :ok} = Backend.write(fs, "path.txt", "path")
      {fs, :ok} = Backend.write(fs, "path2.txt", "path2")

      auto_assert(
        %{
          "/" => %Virtfs.File{kind: :dir, path: "/"},
          "/a" => %Virtfs.File{kind: :dir, path: "/a"},
          "/a/b" => %Virtfs.File{kind: :dir, path: "/a/b"},
          "/a/b/path.txt" => %Virtfs.File{content: "path", path: "/a/b/path.txt"},
          "/a/b/path2.txt" => %Virtfs.File{content: "path2", path: "/a/b/path2.txt"}
        } <- fs.files
      )
    end
  end

  describe "read" do
    test "works - simple" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.write(fs, "/path.txt", "path")
      {fs, :ok} = Backend.write(fs, "/path2.txt", "path2")

      auto_assert({:ok, "path"} <- Backend.read(fs, "/path.txt") |> Util.ok!())

      auto_assert({:ok, "path2"} <- Backend.read(fs, "/path2.txt") |> Util.ok!())
    end

    test "works - nested" do
      fs = Virtfs.init()

      {fs, :ok} = Backend.cd(fs, "a/b")
      {fs, :ok} = Backend.write(fs, "path.txt", "path")
      {fs, :ok} = Backend.write(fs, "path2.txt", "path2")

      auto_assert({:ok, "path"} <- Backend.read(fs, "path.txt") |> Util.ok!())

      auto_assert({:ok, "path"} <- Backend.read(fs, "/a/b/path.txt") |> Util.ok!())

      auto_assert(
        {%Virtfs.FS{
           cwd: "/a/b",
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
             "/a" => %Virtfs.File{kind: :dir, path: "/a"},
             "/a/b" => %Virtfs.File{kind: :dir, path: "/a/b"},
             "/a/b/path.txt" => %Virtfs.File{content: "path", path: "/a/b/path.txt"},
             "/a/b/path2.txt" => %Virtfs.File{content: "path2", path: "/a/b/path2.txt"}
           }
         }, {:error, {:error, :not_found}}} <- Backend.read(fs, "/path.txt")
      )
    end
  end

  describe "rm" do
    test "works only for files" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.cd(fs, "a/b")
      {fs, :ok} = Backend.write(fs, "path.txt", "path")
      {fs, :ok} = Backend.write(fs, "path2.txt", "path2")
      {fs, :ok} = Backend.rm(fs, "path.txt")

      auto_assert(
        %{
          "/" => %Virtfs.File{kind: :dir, path: "/"},
          "/a" => %Virtfs.File{kind: :dir, path: "/a"},
          "/a/b" => %Virtfs.File{kind: :dir, path: "/a/b"},
          "/a/b/path2.txt" => %Virtfs.File{content: "path2", path: "/a/b/path2.txt"}
        } <- fs.files
      )
    end

    test "does not work for folders" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.cd(fs, "a/b")
      {fs, :ok} = Backend.write(fs, "path.txt", "path")
      {fs, :ok} = Backend.write(fs, "path2.txt", "path2")
      {fs, :ok} = Backend.rm(fs, "/first")

      auto_assert({:ok, ["/a/b"]} <- Backend.ls(fs, "/a") |> Util.ok!())
    end
  end

  describe "cd" do
    test ".. works" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.cd(fs, "a/b")
      auto_assert("/a/b" <- fs.cwd)

      {fs, :ok} = Backend.cd(fs, "..")
      auto_assert("/a" <- fs.cwd)

      {fs, :ok} = Backend.cd(fs, "..")
      auto_assert("/" <- fs.cwd)

      {fs, :ok} = Backend.cd(fs, "..")
      auto_assert("/" <- fs.cwd)
    end

    test ".. with mixed instructions works" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.cd(fs, "/a/b/c")
      auto_assert("/a/b/c" <- fs.cwd)

      {fs, :ok} = Backend.cd(fs, "../fourth")
      auto_assert("/a/b/fourth" <- fs.cwd)

      {fs, :ok} = Backend.cd(fs, "..")
      auto_assert("/a/b" <- fs.cwd)

      {fs, :ok} = Backend.cd(fs, "..")
      auto_assert("/a" <- fs.cwd)
    end
  end

  describe "ls" do
    test "works for the current folder" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.cd(fs, "/a/b/c")
      {fs, :ok} = Backend.mkdir_p(fs, "my/nested/folder")
      {fs, :ok} = Backend.mkdir_p(fs, "my/nested/folder2")
      {fs, :ok} = Backend.mkdir_p(fs, "my/nested/folder3")
      {fs, :ok} = Backend.write(fs, "my/nested/folder/file.txt", "content")

      auto_assert({:ok, ["/a/b/c/my/nested"]} <- Backend.ls(fs, "my") |> Util.ok!())

      auto_assert(
        {:ok, ["/a/b/c/my/nested/folder", "/a/b/c/my/nested/folder2", "/a/b/c/my/nested/folder3"]} <-
          Backend.ls(fs, "my/nested") |> Util.ok!()
      )

      auto_assert(
        {:ok, ["/a/b/c/my/nested/folder/file.txt"]} <-
          Backend.ls(fs, "my/nested/folder") |> Util.ok!()
      )
    end

    test "works for top folder" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.write(fs, "file1.txt", "content")
      {fs, :ok} = Backend.write(fs, "file2.txt", "content")

      auto_assert({:ok, ["/file1.txt", "/file2.txt"]} <- Backend.ls(fs, "/") |> Util.ok!())
    end
  end

  describe "tree" do
    test "returns recursivelly files below given path" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.cd(fs, "/a/b/c")
      {fs, :ok} = Backend.mkdir_p(fs, "my/nested/folder")
      {fs, :ok} = Backend.mkdir_p(fs, "my/nested/folder2")
      {fs, :ok} = Backend.mkdir_p(fs, "my/nested/folder3")
      {fs, :ok} = Backend.write(fs, "my/nested/folder/file.txt", "content")

      auto_assert({:ok, []} <- Backend.tree(fs, "/first") |> Util.ok!())

      auto_assert(
        {:ok,
         [
           "/a/b/c/my/nested/folder",
           "/a/b/c/my/nested/folder/file.txt",
           "/a/b/c/my/nested/folder2",
           "/a/b/c/my/nested/folder3"
         ]} <- Backend.tree(fs, "my/nested") |> Util.ok!()
      )
    end

    test "works for root" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.write(fs, "folder/file1.txt", "content")
      {fs, :ok} = Backend.write(fs, "folder/file2.txt", "content")
      {fs, :ok} = Backend.mkdir_p(fs, "folder/sub1/sub2")
      {fs, :ok} = Backend.cp_r(fs, "folder", "folder2")

      auto_assert(
        {:ok,
         [
           "/folder",
           "/folder/file1.txt",
           "/folder/file2.txt",
           "/folder/sub1",
           "/folder/sub1/sub2",
           "/folder2",
           "/folder2/file1.txt",
           "/folder2/file2.txt",
           "/folder2/sub1",
           "/folder2/sub1/sub2"
         ]} <- Backend.tree(fs, "/") |> Util.ok!()
      )
    end
  end

  describe "mkdir_p" do
    test "creates full hierarchy of folders" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.cd(fs, "/a/b/c")
      {fs, :ok} = Backend.mkdir_p(fs, "my/nested/folder")

      auto_assert(
        %{
          "/" => %Virtfs.File{kind: :dir, path: "/"},
          "/a" => %Virtfs.File{kind: :dir, path: "/a"},
          "/a/b" => %Virtfs.File{kind: :dir, path: "/a/b"},
          "/a/b/c" => %Virtfs.File{kind: :dir, path: "/a/b/c"},
          "/a/b/c/my" => %Virtfs.File{kind: :dir, path: "/a/b/c/my"},
          "/a/b/c/my/nested" => %Virtfs.File{kind: :dir, path: "/a/b/c/my/nested"},
          "/a/b/c/my/nested/folder" => %Virtfs.File{kind: :dir, path: "/a/b/c/my/nested/folder"}
        } <- fs.files
      )
    end

    test "does not duplicate folders" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.cd(fs, "/a/")
      {fs, :ok} = Backend.mkdir_p(fs, "my/nested/folder")
      {fs, :ok} = Backend.mkdir_p(fs, "my/nested/folder")
      {fs, :ok} = Backend.cd(fs, "..")
      {fs, :ok} = Backend.mkdir_p(fs, "a/my/nested/folder")

      auto_assert(
        %{
          "/" => %Virtfs.File{kind: :dir, path: "/"},
          "/a" => %Virtfs.File{kind: :dir, path: "/a"},
          "/a/my" => %Virtfs.File{kind: :dir, path: "/a/my"},
          "/a/my/nested" => %Virtfs.File{kind: :dir, path: "/a/my/nested"},
          "/a/my/nested/folder" => %Virtfs.File{kind: :dir, path: "/a/my/nested/folder"}
        } <- fs.files
      )
    end
  end

  describe "rm_rf" do
    test "removes a folder with full content (and subfolders)" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.cd(fs, "/a")
      {fs, :ok} = Backend.mkdir_p(fs, "nested/folder")
      {fs, :ok} = Backend.write(fs, "nested/folder/file.txt1", "content")

      auto_assert(
        %{
          "/" => %Virtfs.File{kind: :dir, path: "/"},
          "/a" => %Virtfs.File{kind: :dir, path: "/a"},
          "/a/nested" => %Virtfs.File{kind: :dir, path: "/a/nested"},
          "/a/nested/folder" => %Virtfs.File{kind: :dir, path: "/a/nested/folder"},
          "/a/nested/folder/file.txt1" => %Virtfs.File{
            content: "content",
            path: "/a/nested/folder/file.txt1"
          }
        } <- fs.files
      )

      {fs, :ok} = Backend.rm_rf(fs, "/first/nested")

      auto_assert(
        %{
          "/" => %Virtfs.File{kind: :dir, path: "/"},
          "/a" => %Virtfs.File{kind: :dir, path: "/a"},
          "/a/nested" => %Virtfs.File{kind: :dir, path: "/a/nested"},
          "/a/nested/folder" => %Virtfs.File{kind: :dir, path: "/a/nested/folder"},
          "/a/nested/folder/file.txt1" => %Virtfs.File{
            content: "content",
            path: "/a/nested/folder/file.txt1"
          }
        } <- fs.files
      )
    end
  end

  describe "rename" do
    test "works with existing files" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.cd(fs, "/a/b/c")
      {fs, :ok} = Backend.mkdir_p(fs, "my/nested/folder")
      {fs, :ok} = Backend.write(fs, "file1.txt", "content")
      {fs, :ok} = Backend.cd(fs, "/")

      auto_assert(
        {:ok,
         [
           "/a",
           "/a/b",
           "/a/b/c",
           "/a/b/c/file1.txt",
           "/a/b/c/my",
           "/a/b/c/my/nested",
           "/a/b/c/my/nested/folder"
         ]} <- Backend.tree(fs, "/") |> Util.ok!()
      )

      {fs, :ok} = Backend.rename(fs, "/a/b/c/file1.txt", "/a/b/file1.txt")

      auto_assert(
        {:ok,
         ["/a/b/c", "/a/b/c/my", "/a/b/c/my/nested", "/a/b/c/my/nested/folder", "/a/b/file1.txt"]} <-
          Backend.tree(fs, "/a/b") |> Util.ok!()
      )
    end

    test "does not work with missing files" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.write(fs, "file1.txt", "content")
      {fs, {:error, :source_not_found}} = Backend.rename(fs, "missing.txt", "file1.txt")

      auto_assert({:ok, ["/file1.txt"]} <- Backend.tree(fs, "/") |> Util.ok!())
    end

    test "also renames subfolders and subfiles" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.mkdir_p(fs, "a/b/c/d")
      {fs, :ok} = Backend.write(fs, "a/b/file1.txt", "content")
      {fs, :ok} = Backend.rename(fs, "a/b", "a/GGG")

      auto_assert(
        {:ok, ["/a/GGG/c", "/a/GGG/c/d", "/a/GGG/file1.txt", "/a/b"]} <-
          Backend.tree(fs, "/a") |> Util.ok!()
      )
    end
  end

  describe "cp" do
    test "works for files" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.write(fs, "file1.txt", "content")
      {fs, :ok} = Backend.cp(fs, "file1.txt", "file2.txt")

      auto_assert({:ok, ["/file1.txt", "/file2.txt"]} <- Backend.ls(fs, "/") |> Util.ok!())

      auto_assert({:ok, "content"} <- Backend.read(fs, "file2.txt") |> Util.ok!())
    end

    test "does not work for folders" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.write(fs, "folder/file1.txt", "content")
      {fs, {:error, :source_is_dir}} = Backend.cp(fs, "folder", "folder2")

      auto_assert({:ok, ["/folder"]} <- Backend.ls(fs, "/") |> Util.ok!())
      auto_assert({:error, :not_found} <- Backend.ls(fs, "/folder2") |> Util.error!())
    end

    test "does not work for non-existing files" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.write(fs, "folder/file1.txt", "content")

      {fs, {:error, :source_not_found}} =
        Backend.cp(fs, "folder/file-does-not-exist.txt", "folder2")

      auto_assert({:ok, ["/folder"]} <- Backend.ls(fs, "/") |> Util.ok!())
      auto_assert({:error, :not_found} <- Backend.ls(fs, "/folder2") |> Util.error!())
    end
  end

  describe "cp_r" do
    test "works for files" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.write(fs, "file1.txt", "content")
      {fs, :ok} = Backend.cp_r(fs, "file1.txt", "file2.txt")

      auto_assert({:ok, ["/file1.txt", "/file2.txt"]} <- Backend.ls(fs, "/") |> Util.ok!())

      auto_assert({:ok, "content"} <- Backend.read(fs, "file2.txt") |> Util.ok!())
    end

    test "works for folders" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.write(fs, "folder/file1.txt", "content")
      {fs, :ok} = Backend.write(fs, "folder/file2.txt", "content")
      {fs, :ok} = Backend.mkdir_p(fs, "folder/sub1/sub2")
      {fs, :ok} = Backend.cp_r(fs, "folder", "folder2")

      auto_assert(
        {:ok,
         [
           "/folder",
           "/folder/file1.txt",
           "/folder/file2.txt",
           "/folder/sub1",
           "/folder/sub1/sub2",
           "/folder2",
           "/folder2/file1.txt",
           "/folder2/file2.txt",
           "/folder2/sub1",
           "/folder2/sub1/sub2"
         ]} <- Backend.tree(fs, "/") |> Util.ok!()
      )

      auto_assert(
        {:ok, ["/folder2/file1.txt", "/folder2/file2.txt", "/folder2/sub1", "/folder2/sub1/sub2"]} <-
          Backend.tree(fs, "/folder2") |> Util.ok!()
      )

      auto_assert(
        {:ok, ["/folder/file1.txt", "/folder/file2.txt", "/folder/sub1", "/folder/sub1/sub2"]} <-
          Backend.tree(fs, "/folder") |> Util.ok!()
      )
    end

    test "has errors for not-existing src files" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.mkdir_p(fs, "a/b/c")
      {_, {:error, :source_not_found}} = Backend.cp_r(fs, "a/does-not-exist", "d/f")
    end
  end
end
