defmodule Virtfs do
  @moduledoc """
  Documentation for `Virtfs`.
  """
  alias Virtfs.FS
  alias Virtfs.Backend.VirtualFS
  alias Virtfs.Backend.RealFS
  use Virtfs.GenBehaviour

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
end
