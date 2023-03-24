# Virtfs

`Virtfs` is a virtual system, that provides an in-memory file-system. This is very helpful when testing complex file generation scenarios (like code generation). The API is very simple and leaky, because we assume that we deal with generation of small files.

## Usage

```elixir
# start a real FS system
fs = Virtfs.init(type: :virt, path: "/tmp")

# start a virtual FS system
fs = Virtfs.init(type: :real, path: "/tmp")



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
