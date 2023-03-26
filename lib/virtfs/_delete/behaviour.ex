defmodule Virtfs.Behaviour do
  alias Virtfs.FS

  @callback write(fs :: FS, path :: String.t(), content :: String.t()) :: :ok | {:error, any()}
  @callback write!(fs :: FS, path :: String.t(), content :: String.t()) :: :ok

  @callback read(fs :: FS, path :: String.t()) :: {:ok, String.t()} | {:error, any()}
  @callback read!(fs :: FS, path :: String.t()) :: {:ok, String.t()}

  @callback rm(fs :: FS, path :: String.t()) :: :ok | {:error, any()}
  @callback rm!(fs :: FS, path :: String.t()) :: :ok

  @callback rm_rf(fs :: FS, path :: String.t()) :: :ok | {:error, any()}
  @callback rm_rf!(fs :: FS, path :: String.t()) :: :ok

  @callback mkdir_p(fs :: FS, path :: String.t()) :: :ok | {:error, any()}
  @callback mkdir_p!(fs :: FS, path :: String.t()) :: :ok

  @callback copy(fs :: FS, src :: String.t(), dest :: String.t()) :: :ok | {:error, any()}
  @callback copy!(fs :: FS, src :: String.t(), dest :: String.t()) :: :ok

  @callback rename(fs :: FS, src :: String.t(), dest :: String.t()) :: :ok | {:error, any()}
  @callback rename!(fs :: FS, src :: String.t(), dest :: String.t()) :: :ok

  @callback cd(fs :: FS, path :: String.t()) :: :ok | {:error, any()}
  @callback cd!(fs :: FS, path :: String.t()) :: :ok

  @callback ls(fs :: FS, path :: String.t()) :: :ok | {:error, any()}
  @callback ls!(fs :: FS, path :: String.t()) :: :ok

  @callback exists?(fs :: FS, path :: String.t()) :: true | false
  @callback dir?(fs :: FS, path :: String.t()) :: true | false
end
