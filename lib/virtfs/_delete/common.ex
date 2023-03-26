defmodule Virtfs.Backend.Common do
  alias Virtfs.File
  alias Virtfs.FS

  def del_file(%FS{files: files} = fs, %File{path: path}) do
    files = Map.delete(files, path)
    %FS{fs | files: files}
  end

  def del_file(%FS{files: files} = fs, path) when is_binary(path) do
    files = Map.delete(files, path)
    %FS{fs | files: files}
  end

  def store_file(%FS{files: files} = fs, %File{path: path} = file) do
    files = Map.put(files, path, file)
    %FS{fs | files: files}
  end
end
