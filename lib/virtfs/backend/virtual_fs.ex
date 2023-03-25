defmodule Virtfs.Backend.VirtualFS do
  alias Virtfs.File
  alias Virtfs.FS
  # @behaviour Virtfs.Behaviour

  def write(%FS{} = fs, path, content) do
    full_path = Path.join(fs.cwd, path)
    file = %File{path: full_path, content: content}
    files = Map.put(fs.files, full_path, file)

    {:ok, update_fs(fs, :files, files)}
  end

  def read(fs, path) do
    full_path = to_fullpath(fs.cwd, path)
    file = Map.get(fs.files, full_path)

    cond do
      file == nil -> {:error, :not_found}
      true -> {:ok, file.content}
    end
  end

  def rm(fs, path) do
    full_path = to_fullpath(fs.cwd, path)
    files = Map.delete(fs.files, full_path)
    {:ok, update_fs(fs, :files, files)}
  end

  def ls(fs, path) do
    full_path = to_fullpath(fs.cwd, path)
    paths = Map.keys(fs.files)
    found = Enum.filter(paths, fn p -> String.contains?(p, full_path) end)
    {:ok, found}
  end

  def rm_rf(fs, path) do
    full_path = to_fullpath(fs.cwd, path)
    paths = Map.keys(fs.files)
    found = Enum.filter(paths, fn p -> String.contains?(p, full_path) end)

    files =
      Enum.reduce(found, fs.files, fn p, files ->
        Map.delete(files, p)
      end)

    {:ok, update_fs(fs, :files, files)}
  end

  def mkdir_p(fs, path) do
    full_path = to_fullpath(fs.cwd, path)

    file = Map.get(fs.files, full_path)
    dir = File.new_dir(path)

    files =
      cond do
        file == nil -> Map.put(fs.files, path, dir)
      end

    {:ok, update_fs(fs, :files, files)}
  end

  def copy(fs, src, dest) do
    full_src = to_fullpath(fs.cwd, src)
    full_dest = to_fullpath(fs.cwd, dest)

    file = Map.get(fs.files, full_src)

    files =
      cond do
        file == nil -> fs.files
        file.kind == :dir -> Map.put(fs.files, full_dest, file)
        file.kind == :file -> Map.put(fs.files, full_dest, file)
      end

    {:ok, update_fs(fs, :files, files)}
  end

  def rename(fs, src, dest) do
    full_src = to_fullpath(fs.cwd, src)
    full_dest = to_fullpath(fs.cwd, dest)
    file = Map.get(fs.files, full_src)

    files =
      cond do
        file == nil ->
          fs.files

        file.kind == :dir ->
          Map.delete(fs.files, full_src) |> Map.put(full_dest, Map.put(file, :path, full_dest))

        file.kind == :file ->
          Map.delete(fs.files, full_src) |> Map.put(full_dest, Map.put(file, :path, full_dest))
      end

    {:ok, update_fs(fs, :files, files)}
  end

  ## Nav
  def cd(fs, path) do
    full_path = to_fullpath(fs.cwd, path)
    {:ok, update_fs(fs, :cwd, full_path)}
  end

  def exists?(fs, path) do
    full_path = to_fullpath(fs.cwd, path)
    file = Map.get(fs.files, full_path)
    {:ok, file != nil}
  end

  def dir?(fs, path) do
    full_path = to_fullpath(fs.cwd, path)
    file = Map.get(fs.files, full_path)

    res =
      cond do
        file == nil -> false
        file.kind == :dir -> true
        true -> false
      end

    {:ok, res}
  end

  defp to_fullpath(cwd, path) do
    res =
      if String.starts_with?(path, "/") do
        path
      else
        Path.join(cwd, path)
      end

    Virtfs.Path.expand_dot(res)
  end

  def update_fs(fs, :files, files) do
    %FS{fs | files: files}
  end

  def update_fs(fs, :cwd, path) do
    %FS{fs | cwd: path}
  end
end
