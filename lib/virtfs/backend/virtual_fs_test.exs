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
      fs = Virtfs.init()
      {:ok, fs} = VirtualFS.cd(fs, "first/second")
      {:ok, fs} = VirtualFS.write(fs, "path.txt", "path")
      {:ok, fs} = VirtualFS.write(fs, "path2.txt", "path2")
      {:ok, fs} = VirtualFS.rm(fs, "path.txt")
      {:ok, fs} = VirtualFS.cd(fs, "..")
      {:ok, fs} = VirtualFS.cd(fs, "..")

      auto_assert(
        %{
          "/first/second/path2.txt" => %Virtfs.File{
            content: "path2",
            path: "/first/second/path2.txt"
          }
        } <- fs.files
      )
    end
  end
end
