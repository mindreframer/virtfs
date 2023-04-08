defmodule Virtfs.Loader do
  alias Virtfs.Backend

  @doc """

  Whitelist options for a typical Elixir project:

    ```elixir
    whitelist = [
      "{.formatter.exs,.gitignore,.iex.exs,CHANGELOG.md,README.md,TODO.txt,mix.exs,mix.lock}",
      "{.github}/**",
      "{lib,test}/**"
    ]
    ```
  """
  def run(%Virtfs.FS{} = fs, src, opts \\ []) do
    # by default we load ALL files!
    whitelist = Keyword.get(opts, :whitelist, ["**/**"])

    files =
      whitelist
      |> Enum.map(fn glob -> "#{src}/#{glob}" end)
      |> Enum.flat_map(fn x -> Path.wildcard(x, match_dot: true) end)

    fs =
      Enum.reduce(files, fs, fn path, fs ->
        relpath = relative_path(src, path)
        type = ftype(path)

        cond do
          type == :dir -> Backend.mkdir_p(fs, relpath) |> elem(0)
          type == :file -> Backend.write(fs, relpath, File.read!(path)) |> elem(0)
          # we ignore symlinks for now
          type == :symlink -> fs
        end
      end)

    # TODO: handle errors ?
    {:ok, fs}
  end

  def relative_path(dest, path) do
    String.replace_leading(path, dest, "")
  end

  def ftype(path) do
    res = File.stat(path)

    case res do
      {:ok, %{type: :regular}} -> :file
      {:ok, %{type: :directory}} -> :dir
      {:error, :enoent} -> check_symlink(path)
    end
  end

  def check_symlink(path) do
    res = File.read_link(path)

    case res do
      {:ok, _link_path} -> :symlink
      {:error, _} -> :error
    end
  end
end
