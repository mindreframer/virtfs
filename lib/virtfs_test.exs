defmodule VirtfsTest do
  use ExUnit.Case
  use Mneme, action: :accept, default_pattern: :last

  setup :new_fs

  describe "read!" do
    test "write! / read! work", %{fs: fs} do
      auto_assert(:ok <- Virtfs.mkdir_p!(fs, "/a/b/c"))
      auto_assert(:ok <- Virtfs.write(fs, "/a/d/f/file.txt", "my poem/nand more!"))
      auto_assert("my poem/nand more!" <- Virtfs.read!(fs, "/a/d/f/file.txt"))
    end

    test "raises on invalid input", %{fs: fs} do
      assert_raise RuntimeError, "{{:error, :not_found}, {:read!, \"/a\"}}", fn ->
        auto_assert(:ok <- Virtfs.read!(fs, "/a"))
      end
    end
  end

  describe "append" do
    test "simple append works", %{fs: fs} do
      auto_assert(:ok <- Virtfs.mkdir_p!(fs, "/a"))
      auto_assert(:ok <- Virtfs.write(fs, "/a/file.txt", "my poem\nand more!"))
      auto_assert(:ok <- Virtfs.append!(fs, "/a/file.txt", "---more-content"))

      auto_assert(
        """
        my poem
        and more!---more-content\
        """ <- Virtfs.read!(fs, "/a/file.txt")
      )
    end

    test "simple append_line works", %{fs: fs} do
      auto_assert(:ok <- Virtfs.mkdir_p!(fs, "/a"))
      auto_assert(:ok <- Virtfs.write(fs, "/a/file.txt", "my poem\nand more!"))
      auto_assert(:ok <- Virtfs.append_line!(fs, "/a/file.txt", "---more-content"))
      auto_assert(:ok <- Virtfs.append_line!(fs, "/a/file.txt", "---2more-content"))

      auto_assert(
        """
        my poem
        and more!
        ---more-content
        ---2more-content\
        """ <- Virtfs.read!(fs, "/a/file.txt")
      )
    end
  end

  describe "ls!" do
    test "write! / read! work", %{fs: fs} do
      auto_assert(:ok <- Virtfs.mkdir_p!(fs, "/a/b/c"))
      auto_assert(:ok <- Virtfs.write(fs, "/a/b/file.txt", "my poem/nand more!"))
      auto_assert(["/a/b/c", "/a/b/file.txt"] <- Virtfs.ls!(fs, "/a/b"))
    end

    test "raises on invalid input", %{fs: fs} do
      assert_raise RuntimeError, "{{:error, :not_found}, {:ls!, \"/a/--\"}}", fn ->
        auto_assert(:ok <- Virtfs.ls!(fs, "/a/--"))
      end
    end
  end

  describe "rm!" do
    test "works", %{fs: fs} do
      auto_assert(:ok <- Virtfs.mkdir_p!(fs, "/a/b/c"))
      auto_assert(:ok <- Virtfs.write(fs, "/a/b/file.txt", "my poem/nand more!"))
      auto_assert(["/a/b/c", "/a/b/file.txt"] <- Virtfs.ls!(fs, "/a/b"))
      auto_assert(:ok <- Virtfs.rm!(fs, "/a/b/file.txt"))
    end

    test "raises on invalid input", %{fs: fs} do
      assert_raise RuntimeError, "{{:error, :source_not_found}, {:rm!, \"--file--\"}}", fn ->
        auto_assert(:ok <- Virtfs.rm!(fs, "--file--"))
      end
    end
  end

  describe "rename!" do
    test "works", %{fs: fs} do
      auto_assert(:ok <- Virtfs.mkdir_p!(fs, "/a/b/c"))
      auto_assert(:ok <- Virtfs.write(fs, "/a/b/file.txt", "my poem/nand more!"))
      auto_assert(["/a/b/c", "/a/b/file.txt"] <- Virtfs.ls!(fs, "/a/b"))
      auto_assert(:ok <- Virtfs.rename!(fs, "/a/b", "a/new"))
      auto_assert(["/a", "/a/new", "/a/new/c", "/a/new/file.txt"] <- Virtfs.tree!(fs, "/"))
    end

    test "raises on invalid input", %{fs: fs} do
      assert_raise RuntimeError,
                   "{{:error, :source_not_found}, {:rename!, \"/a\", \"/b\"}}",
                   fn ->
                     auto_assert(:ok <- Virtfs.rename!(fs, "/a", "/b"))
                   end
    end
  end

  describe "cp_r!" do
    test "works", %{fs: fs} do
      auto_assert(:ok <- Virtfs.mkdir_p!(fs, "/a/b/c"))
      auto_assert(:ok <- Virtfs.write(fs, "/a/b/file.txt", "my poem/nand more!"))
      auto_assert(["/a/b/c", "/a/b/file.txt"] <- Virtfs.ls!(fs, "/a/b"))
      auto_assert(:ok <- Virtfs.cp_r!(fs, "/a/b", "a/new"))

      auto_assert(
        ["/a", "/a/b", "/a/b/c", "/a/b/file.txt", "/a/new", "/a/new/c", "/a/new/file.txt"] <-
          Virtfs.tree!(fs, "/")
      )

      auto_assert({:ok, "my poem/nand more!"} <- Virtfs.read(fs, "/a/new/file.txt"))
    end

    test "raises on invalid input", %{fs: fs} do
      assert_raise RuntimeError,
                   "{{:error, :source_not_found}, {:cp_r!, \"/a\", \"/b\"}}",
                   fn ->
                     auto_assert(:ok <- Virtfs.cp_r!(fs, "/a", "/b"))
                   end
    end
  end

  describe "mkdir_p!" do
    test "works on valid input", %{fs: fs} do
      auto_assert(:ok <- Virtfs.mkdir_p!(fs, "/a/b/c"))
      auto_assert(:ok <- Virtfs.mkdir_p!(fs, "/a/d/f"))
      auto_assert(["/a/b", "/a/b/c", "/a/d", "/a/d/f"] <- Virtfs.tree!(fs, "/a"))
    end

    test "works on invalid input", %{fs: _fs} do
      # TODO maybe cover input validation later
      # auto_assert(:ok <- Virtfs.mkdir_p!(fs, ))
    end
  end

  describe "cwd" do
    test "returns current workind dir", %{fs: fs} do
      auto_assert(:ok <- Virtfs.mkdir_p!(fs, "/a/b/c"))
      auto_assert(:ok <- Virtfs.mkdir_p!(fs, "/a/d/f"))
      auto_assert("/" <- Virtfs.cwd(fs))

      auto_assert(:ok <- Virtfs.cd(fs, "/a/b"))
      auto_assert("/a/b" <- Virtfs.cwd(fs))

      auto_assert({:error, :not_found} <- Virtfs.cd(fs, "/a/b/d/e/g/f/h"))
      auto_assert("/a/b" <- Virtfs.cwd(fs))
    end
  end

  describe "expand" do
    test "works", %{fs: fs} do
      auto_assert(:ok <- Virtfs.mkdir_p!(fs, "/a/b/c"))
      auto_assert(:ok <- Virtfs.mkdir_p!(fs, "/a/b/d"))
      auto_assert(:ok <- Virtfs.cd(fs, "/a/b"))
      auto_assert("/a/b/some/random/path" <- Virtfs.expand!(fs, "some/random/path"))
      auto_assert("/a/d/another/folder" <- Virtfs.expand!(fs, "../d/another/folder"))
    end
  end

  describe "relative_to_cwd" do
    test "works", %{fs: fs} do
      auto_assert(:ok <- Virtfs.mkdir_p!(fs, "/a/b/c"))
      auto_assert(:ok <- Virtfs.mkdir_p!(fs, "/a/b/d"))
      auto_assert(:ok <- Virtfs.cd(fs, "/a/b"))

      auto_assert(
        {:ok, "some/random/path"} <- Virtfs.relative_to_cwd(fs, "/a/b/some/random/path")
      )
    end
  end

  defp new_fs(_) do
    {:ok, fs} = Virtfs.start_link()
    {:ok, %{fs: fs}}
  end
end
