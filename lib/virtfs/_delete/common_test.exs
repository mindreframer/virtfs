defmodule Virtfs.Backend.CommonTest do
  use ExUnit.Case
  use Mneme, action: :accept, default_pattern: :last
  alias Virtfs.Backend.Common
  alias Virtfs.File
  alias Virtfs.FS

  describe "store_file" do
    test "adding file with same path twice results in single file" do
      fs = FS.init()
      file1 = File.new_file("/tmp/here.txt", "content1")
      file2 = File.new_file("/tmp/here.txt", "content2")
      fs = Common.store_file(fs, file1)
      fs = Common.store_file(fs, file2)

      auto_assert(
        %FS{files: %{"/tmp/here.txt" => %File{content: "content2", path: "/tmp/here.txt"}}} <- fs
      )
    end

    setup [:setup_fs]

    test "adding 2 files adds them", %{fs: fs} do
      auto_assert(
        %FS{
          files: %{
            "/tmp/here1.txt" => %File{content: "content1", path: "/tmp/here1.txt"},
            "/tmp/here2.txt" => %File{content: "content2", path: "/tmp/here2.txt"}
          }
        } <- fs
      )
    end
  end

  describe "del_file" do
    setup [:setup_fs]

    test "works", %{fs: fs} do
      fs = Common.del_file(fs, "/tmp/here1.txt")

      auto_assert(
        %FS{files: %{"/tmp/here2.txt" => %File{content: "content2", path: "/tmp/here2.txt"}}} <-
          fs
      )
    end
  end

  def setup_fs(_) do
    fs = FS.init()
    file1 = File.new_file("/tmp/here1.txt", "content1")
    file2 = File.new_file("/tmp/here2.txt", "content2")
    fs = Common.store_file(fs, file1)
    fs = Common.store_file(fs, file2)

    {:ok, %{fs: fs}}
  end
end
