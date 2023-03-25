defmodule Virtfs.FS do
  alias Virtfs.FS
  alias Virtfs.Backend.VirtualFS
  alias Virtfs.Backend.RealFS

  @type kind :: :real | :virt
  use TypedStruct

  typedstruct do
    @typedoc "Virtual Filesystem"

    field(:kind, kind, default: :virt)
    field(:backend, Virtfs.Behaviour, default: VirtualFS)
    field(:cwd, String.t(), default: "/")
    field(:files, map())
  end

  def init(opts \\ []) do
    type = Keyword.get(opts, :type, :virt)
    path = Keyword.get(opts, :path, "/")
    backend = backend_for(type)

    %FS{
      kind: type,
      files: %{
        "/" => Virtfs.File.new_dir("/")
      },
      cwd: path,
      backend: backend
    }
  end

  def backend_for(:virt), do: VirtualFS
  def backend_for(:real), do: RealFS
end
