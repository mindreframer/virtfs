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

  def copy(fs, src, dest) do
    IO.inspect({fs, src, dest})
    :ok
  end

  def copy!(fs, src, dest) do
    IO.inspect({fs, src, dest})
    :ok
  end
end
