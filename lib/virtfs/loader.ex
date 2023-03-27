defmodule Virtfs.Loader do
  alias Virtfs.Backend

  def run(%Virtfs.FS{} = fs, dest, _opts \\ []) do
    # ignore = Keyword.get(opts, :ignore, [])

    # ignore_regexes = Enum.map(ignore, fn(str)-> Regex.buil)
    files = Path.wildcard(dest <> "/**/**")

    fs =
      Enum.reduce(files, fs, fn path, fs ->
        relpath = relative_path(dest, path)
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
