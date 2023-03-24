defmodule Virtfs.Behaviour do
  alias Virtfs.FS

  @callback write(fs :: FS, path :: String.t(), content :: String.t()) :: :ok | {:error, any()}
  @callback write!(fs :: FS, path :: String.t(), content :: String.t()) :: :ok

  @callback read(fs :: FS, path :: String.t()) :: {:ok, String.t()} | {:error, any()}
  @callback read!(fs :: FS, path :: String.t()) :: {:ok, String.t()}

  @callback rm(fs :: FS, path :: String.t()) :: :ok | {:error, any()}
  @callback rm!(fs :: FS, path :: String.t()) :: :ok

  @callback copy(fs :: FS, src :: String.t(), dest :: String.t()) :: :ok | {:error, any()}
  @callback copy!(fs :: FS, src :: String.t(), dest :: String.t()) :: :ok
end
