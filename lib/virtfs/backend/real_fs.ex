defmodule Virtfs.Backend.RealFS do
  @behaviour Virtfs.Behaviour

  def write(fs, path, content) do
    IO.inspect({fs, path, content})
    :ok
  end

  def write!(fs, path, content) do
    IO.inspect({fs, path, content})
    :ok
  end

  def read(fs, path) do
    IO.inspect({fs, path})
    {:ok, ""}
  end

  def read!(fs, path) do
    IO.inspect({fs, path})
    {:ok, ""}
  end

  def rm(fs, path) do
    IO.inspect({fs, path})
    :ok
  end

  def rm!(fs, path) do
    IO.inspect({fs, path})
    :ok
  end

  def rm_rf(fs, path) do
    IO.inspect({fs, path})
    :ok
  end

  def rm_rf!(fs, path) do
    IO.inspect({fs, path})
    :ok
  end

  def mkdir_p(fs, path) do
    IO.inspect({fs, path})
    :ok
  end

  def mkdir_p!(fs, path) do
    IO.inspect({fs, path})
    :ok
  end

  def copy(fs, src, dest) do
    IO.inspect({fs, src, dest})
    :ok
  end

  def copy!(fs, src, dest) do
    IO.inspect({fs, src, dest})
    :ok
  end

  def rename(fs, src, dest) do
    IO.inspect({fs, src, dest})
    :ok
  end

  def rename!(fs, src, dest) do
    IO.inspect({fs, src, dest})
    :ok
  end

  ## Nav
  def cd(fs, path) do
    IO.inspect({fs, path})
    :ok
  end

  def cd!(fs, path) do
    IO.inspect({fs, path})
    :ok
  end

  def exists?(fs, path) do
    IO.inspect({fs, path})
    true
  end

  def dir?(fs, path) do
    IO.inspect({fs, path})
    true
  end
end
