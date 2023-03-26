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
end
