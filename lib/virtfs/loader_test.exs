defmodule Virtfs.LoaderTest do
  use ExUnit.Case
  use Mneme, action: :accept, default_pattern: :last

  alias Virtfs.Server

  describe "run" do
    test "works" do
      {:ok, fs} = Server.start_link()
      Server.mkdir_p!(fs, "/a/b/c")
      Server.load(fs, fixture_path())
      data = Server.get_fs(fs)

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
          "/c" => %Virtfs.File{kind: :dir, path: "/c"},
          "/c/file2.txt" => %Virtfs.File{
            content: """
            and here another file




            fin\
            """,
            path: "/c/file2.txt"
          }
        } <- data.files
      )
    end
  end

  def fixture_path() do
    Path.join(__DIR__, "test_fixtures")
  end
end
