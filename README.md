# Virtfs

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
