defmodule VirtfsTest do
  use ExUnit.Case

  describe "1. scenario" do
    test "works" do
      fs = Virtfs.init()

      Virtfs.write(fs, "folder/file1.txt", "content1")
      Virtfs.write(fs, "folder/file2.txt", "content2")
      Virtfs.write(fs, "folder2/file1.txt", "content1")
      Virtfs.write(fs, "folder2/file2.txt", "content2")
    end
  end
end
