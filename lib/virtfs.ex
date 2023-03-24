defmodule Virtfs do
  @moduledoc """
  Documentation for `Virtfs`.
  """
  alias Virtfs.FS
  alias Virtfs.Backend.VirtualFS
  alias Virtfs.Backend.RealFS

  def init(opts) do
    type = Keyword.get(opts, :type, :virt)
    path = Keyword.get(opts, :path, "/")
    backend = backend_for(type)

    %FS{
      kind: type,
      files: [],
      cwd: path,
      backend: backend
    }
  end

  def backend_for(:virt), do: VirtualFS
  def backend_for(:real), do: RealFS

  def write(fs, path, content) do
    fs.backend.write(fs, path, content)
  end

  def write!(fs, path, content) do
    fs.backend.write!(fs, path, content)
  end

  def read(fs, path) do
    fs.backend.read(fs, path)
  end

  def read!(fs, path) do
    fs.backend.read!(fs, path)
  end

  def rm(fs, path) do
    fs.backend.rm(fs, path)
  end

  def rm!(fs, path) do
    fs.backend.rm!(fs, path)
  end

  def copy(fs, src, dest) do
    fs.backend.copy(fs, src, dest)
  end

  def copy!(fs, src, dest) do
    fs.backend.copy!(fs, src, dest)
  end
end
