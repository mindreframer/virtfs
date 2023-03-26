defmodule Virtfs.Loader do
  alias Virtfs.Backend

  def run(%Virtfs.FS{} = fs, dest) do
    files = Path.wildcard(dest <> "/**/**")

    Enum.reduce(files, fs, fn path, fs ->
      relpath = relative_path(dest, path)
      type = ftype(path)

      cond do
        type == :dir -> Backend.mkdir_p(fs, relpath) |> elem(0)
        type == :file -> Backend.write(fs, relpath, File.read!(path)) |> elem(0)
      end
    end)
  end

  def relative_path(dest, path) do
    String.replace_leading(path, dest, "")
  end

  def ftype(path) do
    stat = File.stat!(path)

    cond do
      stat.type == :regular -> :file
      stat.type == :directory -> :dir
    end
  end
end
