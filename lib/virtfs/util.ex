defmodule Virtfs.Util do
  def ok!({_fs, {:ok, v}}) do
    {:ok, v}
  end

  def ok!({_fs, :ok}) do
    :ok
  end

  def error!({_fs, {:error, v}}) do
    {:error, v}
  end

  def to_fullpath(cwd, path) do
    path = normalize_path(path)

    res =
      if String.starts_with?(path, "/") do
        path
      else
        Path.join(cwd, path)
      end

    Virtfs.Path.expand_dot(res)
  end

  def normalize_path(path) do
    String.replace(path, "//", "/")
  end
end
