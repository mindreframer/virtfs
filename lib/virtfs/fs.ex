defmodule Virtfs.FS do
  alias Virtfs.Backend.Virtual
  alias Virtfs.File

  @type kind :: :real | :virt
  use TypedStruct

  typedstruct do
    @typedoc "Virtual Filesystem"

    field(:kind, kind, default: :virt)
    field(:backend, Virtfs.Behaviour, default: Virtual)
    field(:cwd, String.t(), default: "/")
    field(:files, list(File.t()))
  end
end
