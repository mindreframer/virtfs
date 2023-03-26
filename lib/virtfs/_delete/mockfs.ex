defmodule Virtfs.Mockfs do
  @moduledoc """
  - https://dskrzypiec.dev/mock-go-filesystem/
  - https://blog.victoreronmosele.com/mocking-filesystems-dart
  - https://schibsted.com/blog/mocking-the-file-system-using-phpunit-and-vfsstream/
  - http://tschaub.net/blog/2014/02/17/mocking-the-filesystem.html
  """
  # {:dir, "", [{:file, "name.txt", "content"}, {:file, "name2.txt", "content2"}],
  #  [{:dir, "subdir", []}, {:dir, "subdir2", []}]}

  # {
  #   "path",
  #   [
  #     %{p: "name.txt", c: "content"},
  #     %{p: "name2.txt", c: "content"}
  #   ],
  #   %{"subfolder" => {"subfolder", [], %{}}}
  # }

  #   {"/", %{"some.txt" => "content", "another.txt"> "content2"},
  #         [{"subdir", %{}}, {:dir, "subdir2", []}]
  # }

  # type Dir struct {
  #     Path    string,
  #     Files   []os.FileInfo,
  #     SubDirs map[string]Dir
  # }
end
