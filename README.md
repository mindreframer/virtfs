# Virtfs - In-memory file system for Elixir

https://user-images.githubusercontent.com/1232/227995409-27ff2deb-50e1-4091-a22f-64f141543635.mp4



[![Hex.pm](https://img.shields.io/hexpm/v/virtfs.svg)](https://hex.pm/packages/virtfs)
[![Docs](https://img.shields.io/badge/hexdocs-docs-8e7ce6.svg)](https://hexdocs.pm/virtfs)
[![CI](https://github.com/mindreframer/virtfs/actions/workflows/ci.yml/badge.svg)](https://github.com/mindreframer/virtfs/actions/workflows/ci.yml)

`Virtfs` is a virtual system, that provides an in-memory file-system. This is very helpful when testing complex file generation scenarios (like code generation). The API is very simple and leaky, because we assume that we deal with generation of small files.

## Usage

```elixir
# Start a virtual FS system and play with it
{:ok, fs} = Virtfs.start_link()

# writing
:ok = Virtfs.write!(fs, "some/file.txt", "content")
:ok = Virtfs.write!(fs, "some/file2.txt", "content")

# ls
["/some/file.txt", "/some/file2.txt"] = Virtfs.ls!(fs, "some")

# reading
"content" = Virtfs.read!(fs, "/some/file2.txt")

# cd
:ok = Virtfs.cd(fs, "some")
"content" = Virtfs.read!(fs, "file2.txt")

# tree
["/some", "/some/file.txt", "/some/file2.txt"] == Virtfs.tree!(fs, "/")

# dump in-memory FS into a folder
File.rm_rf("/tmp/virtfs_test")
Virtfs.dump(fs, "/tmp/virtfs_test")
["file2.txt", "file.txt"] = File.ls!("/tmp/virtfs_test/some")


# load files from a folder
{:ok, fs} = Virtfs.start_link()
Virtfs.load(fs, "/tmp/virtfs_test")
["/some", "/some/file.txt", "/some/file2.txt"] = Virtfs.tree!(fs, "/")

```

## Installation

The package can be installed by adding `virtfs` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:virtfs, "~> 0.1.0"}
  ]
end
```

The docs can be found at <https://hexdocs.pm/virtfs>.

## Code stats

```bash
tokei
===============================================================================
 Language            Files        Lines         Code     Comments       Blanks
===============================================================================
 Elixir                 18         1591         1271           36          284
 Makefile                1           11            8            0            3
 Plain Text              3           18            0           11            7
-------------------------------------------------------------------------------
 Markdown                2           28            0           17           11
 |- Elixir               1           35           19            8            8
 (Total)                             63           19           25           19
===============================================================================
 Total                  24         1648         1279           64          305
===============================================================================
```
