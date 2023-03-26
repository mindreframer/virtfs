defmodule Virtfs.FS do
  alias Virtfs.FS
  use TypedStruct

  typedstruct do
    @typedoc "Virtual Filesystem"

    field(:cwd, String.t(), default: "/")
    field(:files, map())
  end

  def init(opts \\ []) do
    path = Keyword.get(opts, :path, "/")

    %FS{
      files: %{
        "/" => Virtfs.File.new_dir("/")
      },
      cwd: path
    }
  end
end
