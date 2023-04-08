defmodule Virtfs.LoaderTest do
  use ExUnit.Case
  use Mneme, action: :accept, default_pattern: :last

  describe "run" do
    test "works" do
      {:ok, fs} = Virtfs.start_link()
      auto_assert(:ok <- Virtfs.mkdir_p!(fs, "/a/b/c"))
      auto_assert(:ok <- Virtfs.load(fs, fixture_path()))
      data = Virtfs.get_fs(fs)

      auto_assert(
        %{
          "/" => %Virtfs.File{kind: :dir, path: "/"},
          "/a" => %Virtfs.File{kind: :dir, path: "/a"},
          "/a/b" => %Virtfs.File{kind: :dir, path: "/a/b"},
          "/a/b/c" => %Virtfs.File{kind: :dir, path: "/a/b/c"},
          "/a/b/file1.txt" => %Virtfs.File{
            content: """
            here some dummy
            content


            with spaces and newlines.

            """,
            path: "/a/b/file1.txt"
          },
          "/x" => %Virtfs.File{kind: :dir, path: "/x"},
          "/x/file2.txt" => %Virtfs.File{
            content: """
            and here another file




            fin\
            """,
            path: "/x/file2.txt"
          }
        } <- data.files
      )
    end

    test "supports whitelisting" do
      {:ok, fs} = Virtfs.start_link()
      auto_assert(:ok <- Virtfs.mkdir_p!(fs, "/a/b/c"))
      Virtfs.load(fs, fixture_path(), whitelist: ["{a}/*"])
      data = Virtfs.get_fs(fs)

      auto_assert(
        %Virtfs.FS{
          files: %{
            "/" => %Virtfs.File{kind: :dir, path: "/"},
            "/a" => %Virtfs.File{kind: :dir, path: "/a"},
            "/a/b" => %Virtfs.File{kind: :dir, path: "/a/b"},
            "/a/b/c" => %Virtfs.File{kind: :dir, path: "/a/b/c"}
          }
        } <- data
      )

      Virtfs.load(fs, fixture_path(), whitelist: ["{a}/**"])

      auto_assert(["/a"] <- Virtfs.ls!(fs, "/"))

      data = Virtfs.get_fs(fs)

      auto_assert(
        %{
          "/" => %Virtfs.File{kind: :dir, path: "/"},
          "/a" => %Virtfs.File{kind: :dir, path: "/a"},
          "/a/b" => %Virtfs.File{kind: :dir, path: "/a/b"},
          "/a/b/c" => %Virtfs.File{kind: :dir, path: "/a/b/c"},
          "/a/b/file1.txt" => %Virtfs.File{
            content: """
            here some dummy
            content


            with spaces and newlines.

            """,
            path: "/a/b/file1.txt"
          }
        } <- data.files
      )
    end
  end

  def fixture_path() do
    Path.join(__DIR__, "test_fixtures")
  end
end
