defmodule Virtfs.BackendTest do
  use ExUnit.Case
  use Mneme, action: :accept, default_pattern: :last

  alias Virtfs.Backend

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
      {fs, :ok} = Backend.cd(fs, "first/second")
      {fs, :ok} = Backend.write(fs, "path.txt", "path")
      {fs, :ok} = Backend.write(fs, "path2.txt", "path2")

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
      {fs, :ok} = Backend.write(fs, "/path.txt", "path")
      {fs, :ok} = Backend.write(fs, "/path2.txt", "path2")

      auto_assert(
        {%Virtfs.FS{
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
             "/path.txt" => %Virtfs.File{content: "path", path: "/path.txt"},
             "/path2.txt" => %Virtfs.File{content: "path2", path: "/path2.txt"}
           }
         }, {:ok, {:ok, "path"}}} <- Backend.read(fs, "/path.txt")
      )

      auto_assert(
        {%Virtfs.FS{
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
             "/path.txt" => %Virtfs.File{content: "path", path: "/path.txt"},
             "/path2.txt" => %Virtfs.File{content: "path2", path: "/path2.txt"}
           }
         }, {:ok, {:ok, "path2"}}} <- Backend.read(fs, "/path2.txt")
      )
    end

    test "works - nested" do
      fs = Virtfs.init()

      {fs, :ok} = Backend.cd(fs, "first/second")
      {fs, :ok} = Backend.write(fs, "path.txt", "path")
      {fs, :ok} = Backend.write(fs, "path2.txt", "path2")

      auto_assert(
        {%Virtfs.FS{
           cwd: "/first/second",
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
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
           }
         }, {:ok, {:ok, "path"}}} <- Backend.read(fs, "path.txt")
      )

      auto_assert(
        {%Virtfs.FS{
           cwd: "/first/second",
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
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
           }
         }, {:ok, {:ok, "path"}}} <- Backend.read(fs, "/first/second/path.txt")
      )

      auto_assert(
        {%Virtfs.FS{
           cwd: "/first/second",
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
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
           }
         }, {:error, {:error, :not_found}}} <- Backend.read(fs, "/path.txt")
      )
    end
  end

  describe "rm" do
    test "works only for files" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.cd(fs, "first/second")
      {fs, :ok} = Backend.write(fs, "path.txt", "path")
      {fs, :ok} = Backend.write(fs, "path2.txt", "path2")
      {fs, :ok} = Backend.rm(fs, "path.txt")

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
      {fs, :ok} = Backend.cd(fs, "first/second")
      {fs, :ok} = Backend.write(fs, "path.txt", "path")
      {fs, :ok} = Backend.write(fs, "path2.txt", "path2")
      {fs, :ok} = Backend.rm(fs, "/first")

      auto_assert(
        {%Virtfs.FS{
           cwd: "/first/second",
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
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
           }
         }, {:ok, ["/first/second"]}} <- Backend.ls(fs, "/first")
      )
    end
  end

  describe "cd" do
    test ".. works" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.cd(fs, "first/second")
      auto_assert("/first/second" <- fs.cwd)

      {fs, :ok} = Backend.cd(fs, "..")
      auto_assert("/first" <- fs.cwd)

      {fs, :ok} = Backend.cd(fs, "..")
      auto_assert("/" <- fs.cwd)

      {fs, :ok} = Backend.cd(fs, "..")
      auto_assert("/" <- fs.cwd)
    end

    test ".. with mixed instructions works" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.cd(fs, "/first/second/third")
      auto_assert("/first/second/third" <- fs.cwd)

      {fs, :ok} = Backend.cd(fs, "../fourth")
      auto_assert("/first/second/fourth" <- fs.cwd)

      {fs, :ok} = Backend.cd(fs, "..")
      auto_assert("/first/second" <- fs.cwd)

      {fs, :ok} = Backend.cd(fs, "..")
      auto_assert("/first" <- fs.cwd)
    end
  end

  describe "ls" do
    test "works for the current folder" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.cd(fs, "/first/second/third")
      {fs, :ok} = Backend.mkdir_p(fs, "my/nested/folder")
      {fs, :ok} = Backend.mkdir_p(fs, "my/nested/folder2")
      {fs, :ok} = Backend.mkdir_p(fs, "my/nested/folder3")
      {fs, :ok} = Backend.write(fs, "my/nested/folder/file.txt", "content")

      auto_assert(
        {%Virtfs.FS{
           cwd: "/first/second/third",
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
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
             },
             "/first/second/third/my/nested/folder/file.txt" => %Virtfs.File{
               content: "content",
               path: "/first/second/third/my/nested/folder/file.txt"
             },
             "/first/second/third/my/nested/folder2" => %Virtfs.File{
               kind: :dir,
               path: "/first/second/third/my/nested/folder2"
             },
             "/first/second/third/my/nested/folder3" => %Virtfs.File{
               kind: :dir,
               path: "/first/second/third/my/nested/folder3"
             }
           }
         }, {:ok, ["/first/second/third/my/nested"]}} <- Backend.ls(fs, "my")
      )

      auto_assert(
        {%Virtfs.FS{
           cwd: "/first/second/third",
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
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
             },
             "/first/second/third/my/nested/folder/file.txt" => %Virtfs.File{
               content: "content",
               path: "/first/second/third/my/nested/folder/file.txt"
             },
             "/first/second/third/my/nested/folder2" => %Virtfs.File{
               kind: :dir,
               path: "/first/second/third/my/nested/folder2"
             },
             "/first/second/third/my/nested/folder3" => %Virtfs.File{
               kind: :dir,
               path: "/first/second/third/my/nested/folder3"
             }
           }
         },
         {:ok,
          [
            "/first/second/third/my/nested/folder",
            "/first/second/third/my/nested/folder2",
            "/first/second/third/my/nested/folder3"
          ]}} <- Backend.ls(fs, "my/nested")
      )

      auto_assert(
        {%Virtfs.FS{
           cwd: "/first/second/third",
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
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
             },
             "/first/second/third/my/nested/folder/file.txt" => %Virtfs.File{
               content: "content",
               path: "/first/second/third/my/nested/folder/file.txt"
             },
             "/first/second/third/my/nested/folder2" => %Virtfs.File{
               kind: :dir,
               path: "/first/second/third/my/nested/folder2"
             },
             "/first/second/third/my/nested/folder3" => %Virtfs.File{
               kind: :dir,
               path: "/first/second/third/my/nested/folder3"
             }
           }
         },
         {:ok, ["/first/second/third/my/nested/folder/file.txt"]}} <-
          Backend.ls(fs, "my/nested/folder")
      )
    end

    test "works for top folder" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.write(fs, "file1.txt", "content")
      {fs, :ok} = Backend.write(fs, "file2.txt", "content")

      auto_assert(
        {%Virtfs.FS{
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
             "/file1.txt" => %Virtfs.File{content: "content", path: "/file1.txt"},
             "/file2.txt" => %Virtfs.File{content: "content", path: "/file2.txt"}
           }
         }, {:ok, ["/file1.txt", "/file2.txt"]}} <- Backend.ls(fs, "/")
      )
    end
  end

  describe "tree" do
    test "returns recursivelly files below given path" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.cd(fs, "/first/second/third")
      {fs, :ok} = Backend.mkdir_p(fs, "my/nested/folder")
      {fs, :ok} = Backend.mkdir_p(fs, "my/nested/folder2")
      {fs, :ok} = Backend.mkdir_p(fs, "my/nested/folder3")
      {fs, :ok} = Backend.write(fs, "my/nested/folder/file.txt", "content")

      auto_assert(
        {%Virtfs.FS{
           cwd: "/first/second/third",
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
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
             },
             "/first/second/third/my/nested/folder/file.txt" => %Virtfs.File{
               content: "content",
               path: "/first/second/third/my/nested/folder/file.txt"
             },
             "/first/second/third/my/nested/folder2" => %Virtfs.File{
               kind: :dir,
               path: "/first/second/third/my/nested/folder2"
             },
             "/first/second/third/my/nested/folder3" => %Virtfs.File{
               kind: :dir,
               path: "/first/second/third/my/nested/folder3"
             }
           }
         },
         {:ok,
          [
            "/first/second",
            "/first/second/third",
            "/first/second/third/my",
            "/first/second/third/my/nested",
            "/first/second/third/my/nested/folder",
            "/first/second/third/my/nested/folder/file.txt",
            "/first/second/third/my/nested/folder2",
            "/first/second/third/my/nested/folder3"
          ]}} <- Backend.tree(fs, "/first")
      )

      auto_assert(
        {%Virtfs.FS{
           cwd: "/first/second/third",
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
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
             },
             "/first/second/third/my/nested/folder/file.txt" => %Virtfs.File{
               content: "content",
               path: "/first/second/third/my/nested/folder/file.txt"
             },
             "/first/second/third/my/nested/folder2" => %Virtfs.File{
               kind: :dir,
               path: "/first/second/third/my/nested/folder2"
             },
             "/first/second/third/my/nested/folder3" => %Virtfs.File{
               kind: :dir,
               path: "/first/second/third/my/nested/folder3"
             }
           }
         },
         {:ok,
          [
            "/first/second/third/my/nested/folder",
            "/first/second/third/my/nested/folder/file.txt",
            "/first/second/third/my/nested/folder2",
            "/first/second/third/my/nested/folder3"
          ]}} <- Backend.tree(fs, "my/nested")
      )
    end

    test "works for root" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.write(fs, "folder/file1.txt", "content")
      {fs, :ok} = Backend.write(fs, "folder/file2.txt", "content")
      {fs, :ok} = Backend.mkdir_p(fs, "folder/sub1/sub2")
      {fs, :ok} = Backend.cp_r(fs, "folder", "folder2")

      auto_assert(
        {%Virtfs.FS{
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
             "/folder" => %Virtfs.File{kind: :dir, path: "/folder"},
             "/folder/file1.txt" => %Virtfs.File{content: "content", path: "/folder/file1.txt"},
             "/folder/file2.txt" => %Virtfs.File{content: "content", path: "/folder/file2.txt"},
             "/folder/sub1" => %Virtfs.File{kind: :dir, path: "/folder/sub1"},
             "/folder/sub1/sub2" => %Virtfs.File{kind: :dir, path: "/folder/sub1/sub2"},
             "/folder2" => %Virtfs.File{kind: :dir, path: "/folder2"},
             "/folder2/file1.txt" => %Virtfs.File{content: "content", path: "/folder2/file1.txt"},
             "/folder2/file2.txt" => %Virtfs.File{content: "content", path: "/folder2/file2.txt"},
             "/folder2/sub1" => %Virtfs.File{kind: :dir, path: "/folder2/sub1"},
             "/folder2/sub1/sub2" => %Virtfs.File{kind: :dir, path: "/folder2/sub1/sub2"}
           }
         },
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
          ]}} <- Backend.tree(fs, "/")
      )
    end
  end

  describe "mkdir_p" do
    test "creates full hierarchy of folders" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.cd(fs, "/first/second/third")
      {fs, :ok} = Backend.mkdir_p(fs, "my/nested/folder")

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
      {fs, :ok} = Backend.cd(fs, "/first/")
      {fs, :ok} = Backend.mkdir_p(fs, "my/nested/folder")
      {fs, :ok} = Backend.mkdir_p(fs, "my/nested/folder")
      {fs, :ok} = Backend.cd(fs, "..")
      {fs, :ok} = Backend.mkdir_p(fs, "first/my/nested/folder")

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

  describe "rm_rf" do
    test "removes a folder with full content (and subfolders)" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.cd(fs, "/first")
      {fs, :ok} = Backend.mkdir_p(fs, "nested/folder")
      {fs, :ok} = Backend.write(fs, "nested/folder/file.txt1", "content")

      auto_assert(
        %{
          "/" => %Virtfs.File{kind: :dir, path: "/"},
          "/first" => %Virtfs.File{kind: :dir, path: "/first"},
          "/first/nested" => %Virtfs.File{kind: :dir, path: "/first/nested"},
          "/first/nested/folder" => %Virtfs.File{kind: :dir, path: "/first/nested/folder"},
          "/first/nested/folder/file.txt1" => %Virtfs.File{
            content: "content",
            path: "/first/nested/folder/file.txt1"
          }
        } <- fs.files
      )

      {fs, :ok} = Backend.rm_rf(fs, "/first/nested")

      auto_assert(
        %{
          "/" => %Virtfs.File{kind: :dir, path: "/"},
          "/first" => %Virtfs.File{kind: :dir, path: "/first"}
        } <- fs.files
      )
    end
  end

  describe "rename" do
    test "works with existing files" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.cd(fs, "/first/second/third")
      {fs, :ok} = Backend.mkdir_p(fs, "my/nested/folder")
      {fs, :ok} = Backend.write(fs, "file1.txt", "content")
      {fs, :ok} = Backend.cd(fs, "/")

      auto_assert(
        {%Virtfs.FS{
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
             "/first" => %Virtfs.File{kind: :dir, path: "/first"},
             "/first/second" => %Virtfs.File{kind: :dir, path: "/first/second"},
             "/first/second/third" => %Virtfs.File{kind: :dir, path: "/first/second/third"},
             "/first/second/third/file1.txt" => %Virtfs.File{
               content: "content",
               path: "/first/second/third/file1.txt"
             },
             "/first/second/third/my" => %Virtfs.File{kind: :dir, path: "/first/second/third/my"},
             "/first/second/third/my/nested" => %Virtfs.File{
               kind: :dir,
               path: "/first/second/third/my/nested"
             },
             "/first/second/third/my/nested/folder" => %Virtfs.File{
               kind: :dir,
               path: "/first/second/third/my/nested/folder"
             }
           }
         },
         {:ok,
          [
            "/first",
            "/first/second",
            "/first/second/third",
            "/first/second/third/file1.txt",
            "/first/second/third/my",
            "/first/second/third/my/nested",
            "/first/second/third/my/nested/folder"
          ]}} <- Backend.tree(fs, "/")
      )

      {fs, :ok} = Backend.rename(fs, "/first/second/third/file1.txt", "/first/second/file1.txt")

      auto_assert(
        {%Virtfs.FS{
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
             "/first" => %Virtfs.File{kind: :dir, path: "/first"},
             "/first/second" => %Virtfs.File{kind: :dir, path: "/first/second"},
             "/first/second/file1.txt" => %Virtfs.File{
               content: "content",
               path: "/first/second/file1.txt"
             },
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
           }
         },
         {:ok,
          [
            "/first/second/file1.txt",
            "/first/second/third",
            "/first/second/third/my",
            "/first/second/third/my/nested",
            "/first/second/third/my/nested/folder"
          ]}} <- Backend.tree(fs, "/first/second")
      )
    end

    test "does not work with missing files - FIXME silent failure" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.write(fs, "file1.txt", "content")
      {fs, :ok} = Backend.rename(fs, "missing.txt", "file1.txt")

      auto_assert(
        {%Virtfs.FS{
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
             "/file1.txt" => %Virtfs.File{content: "content", path: "/file1.txt"}
           }
         }, {:ok, ["/file1.txt"]}} <- Backend.tree(fs, "/")
      )
    end
  end

  describe "cp" do
    test "works for files" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.write(fs, "file1.txt", "content")
      {fs, :ok} = Backend.cp(fs, "file1.txt", "file2.txt")

      auto_assert(
        {%Virtfs.FS{
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
             "/file1.txt" => %Virtfs.File{content: "content", path: "/file1.txt"},
             "/file2.txt" => %Virtfs.File{content: "content", path: "/file2.txt"}
           }
         }, {:ok, ["/file1.txt", "/file2.txt"]}} <- Backend.ls(fs, "/")
      )

      auto_assert(
        {%Virtfs.FS{
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
             "/file1.txt" => %Virtfs.File{content: "content", path: "/file1.txt"},
             "/file2.txt" => %Virtfs.File{content: "content", path: "/file2.txt"}
           }
         }, {:ok, {:ok, "content"}}} <- Backend.read(fs, "file2.txt")
      )
    end

    test "does not work for folders" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.write(fs, "folder/file1.txt", "content")
      {fs, :ok} = Backend.cp(fs, "folder", "folder2")

      auto_assert(
        {%Virtfs.FS{
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
             "/folder" => %Virtfs.File{kind: :dir, path: "/folder"},
             "/folder/file1.txt" => %Virtfs.File{content: "content", path: "/folder/file1.txt"}
           }
         }, {:ok, ["/folder"]}} <- Backend.ls(fs, "/")
      )

      auto_assert(
        {%Virtfs.FS{
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
             "/folder" => %Virtfs.File{kind: :dir, path: "/folder"},
             "/folder/file1.txt" => %Virtfs.File{content: "content", path: "/folder/file1.txt"}
           }
         }, {:error, :not_found}} <- Backend.ls(fs, "/folder2")
      )
    end
  end

  describe "cp_r" do
    test "works for files" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.write(fs, "file1.txt", "content")
      {fs, :ok} = Backend.cp_r(fs, "file1.txt", "file2.txt")

      auto_assert(
        {%Virtfs.FS{
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
             "/file1.txt" => %Virtfs.File{content: "content", path: "/file1.txt"},
             "/file2.txt" => %Virtfs.File{content: "content", path: "/file2.txt"}
           }
         }, {:ok, ["/file1.txt", "/file2.txt"]}} <- Backend.ls(fs, "/")
      )

      auto_assert(
        {%Virtfs.FS{
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
             "/file1.txt" => %Virtfs.File{content: "content", path: "/file1.txt"},
             "/file2.txt" => %Virtfs.File{content: "content", path: "/file2.txt"}
           }
         }, {:ok, {:ok, "content"}}} <- Backend.read(fs, "file2.txt")
      )
    end

    test "works for folders" do
      fs = Virtfs.init()
      {fs, :ok} = Backend.write(fs, "folder/file1.txt", "content")
      {fs, :ok} = Backend.write(fs, "folder/file2.txt", "content")
      {fs, :ok} = Backend.mkdir_p(fs, "folder/sub1/sub2")
      {fs, :ok} = Backend.cp_r(fs, "folder", "folder2")

      auto_assert(
        {%Virtfs.FS{
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
             "/folder" => %Virtfs.File{kind: :dir, path: "/folder"},
             "/folder/file1.txt" => %Virtfs.File{content: "content", path: "/folder/file1.txt"},
             "/folder/file2.txt" => %Virtfs.File{content: "content", path: "/folder/file2.txt"},
             "/folder/sub1" => %Virtfs.File{kind: :dir, path: "/folder/sub1"},
             "/folder/sub1/sub2" => %Virtfs.File{kind: :dir, path: "/folder/sub1/sub2"},
             "/folder2" => %Virtfs.File{kind: :dir, path: "/folder2"},
             "/folder2/file1.txt" => %Virtfs.File{content: "content", path: "/folder2/file1.txt"},
             "/folder2/file2.txt" => %Virtfs.File{content: "content", path: "/folder2/file2.txt"},
             "/folder2/sub1" => %Virtfs.File{kind: :dir, path: "/folder2/sub1"},
             "/folder2/sub1/sub2" => %Virtfs.File{kind: :dir, path: "/folder2/sub1/sub2"}
           }
         },
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
          ]}} <- Backend.tree(fs, "/")
      )

      auto_assert(
        {%Virtfs.FS{
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
             "/folder" => %Virtfs.File{kind: :dir, path: "/folder"},
             "/folder/file1.txt" => %Virtfs.File{content: "content", path: "/folder/file1.txt"},
             "/folder/file2.txt" => %Virtfs.File{content: "content", path: "/folder/file2.txt"},
             "/folder/sub1" => %Virtfs.File{kind: :dir, path: "/folder/sub1"},
             "/folder/sub1/sub2" => %Virtfs.File{kind: :dir, path: "/folder/sub1/sub2"},
             "/folder2" => %Virtfs.File{kind: :dir, path: "/folder2"},
             "/folder2/file1.txt" => %Virtfs.File{content: "content", path: "/folder2/file1.txt"},
             "/folder2/file2.txt" => %Virtfs.File{content: "content", path: "/folder2/file2.txt"},
             "/folder2/sub1" => %Virtfs.File{kind: :dir, path: "/folder2/sub1"},
             "/folder2/sub1/sub2" => %Virtfs.File{kind: :dir, path: "/folder2/sub1/sub2"}
           }
         },
         {:ok,
          ["/folder2/file1.txt", "/folder2/file2.txt", "/folder2/sub1", "/folder2/sub1/sub2"]}} <-
          Backend.tree(fs, "/folder2")
      )

      auto_assert(
        {%Virtfs.FS{
           files: %{
             "/" => %Virtfs.File{kind: :dir, path: "/"},
             "/folder" => %Virtfs.File{kind: :dir, path: "/folder"},
             "/folder/file1.txt" => %Virtfs.File{content: "content", path: "/folder/file1.txt"},
             "/folder/file2.txt" => %Virtfs.File{content: "content", path: "/folder/file2.txt"},
             "/folder/sub1" => %Virtfs.File{kind: :dir, path: "/folder/sub1"},
             "/folder/sub1/sub2" => %Virtfs.File{kind: :dir, path: "/folder/sub1/sub2"},
             "/folder2" => %Virtfs.File{kind: :dir, path: "/folder2"},
             "/folder2/file1.txt" => %Virtfs.File{content: "content", path: "/folder2/file1.txt"},
             "/folder2/file2.txt" => %Virtfs.File{content: "content", path: "/folder2/file2.txt"},
             "/folder2/sub1" => %Virtfs.File{kind: :dir, path: "/folder2/sub1"},
             "/folder2/sub1/sub2" => %Virtfs.File{kind: :dir, path: "/folder2/sub1/sub2"}
           }
         },
         {:ok, ["/folder/file1.txt", "/folder/file2.txt", "/folder/sub1", "/folder/sub1/sub2"]}} <-
          Backend.tree(fs, "/folder")
      )
    end
  end
end
