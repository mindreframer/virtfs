defmodule Virtfs.DumperTest do
  use ExUnit.Case
  use Mneme, action: :accept, default_pattern: :last

  alias Virtfs.Dumper

  describe "run" do
    test "works" do
      fs = prepare_fs_struct()
      dir = System.tmp_dir!() <> "/dumper_test"
      assert Dumper.run(fs, dir) == :ok

      # files = Path.wildcard(dir <> "**/**")
      # IO.inspect(files)
      auto_assert(
        """
        content
        and more\
        """ <- File.read!(Path.join(dir, "/a/b/c/d.txt"))
      )

      File.rm_rf!(dir)
    end
  end

  def prepare_fs_struct do
    {:ok, fs} = Virtfs.start_link()
    Virtfs.mkdir_p!(fs, "/a/b/c")
    Virtfs.write!(fs, "/a/b/c/d.txt", "content\nand more")
    Virtfs.write!(fs, "/a/b/c/g.txt", "content\nand more")
    Virtfs.write!(fs, "/a/file1.txt", "content\nand more")
    Virtfs.get_fs(fs)
  end
end
