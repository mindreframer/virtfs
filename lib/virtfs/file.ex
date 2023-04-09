defmodule Virtfs.File do
  @type kind :: :file | :dir

  use Virtfs.TypedStruct

  typedstruct do
    @typedoc "A File"

    field(:kind, kind, default: :file)
    field(:content, String.t(), default: "")
    field(:path, String.t(), enforce: true)
  end

  def new_file(path, content) do
    %Virtfs.File{
      kind: :file,
      path: path,
      content: content
    }
  end

  def new_dir(path) do
    %Virtfs.File{
      kind: :dir,
      path: path
    }
  end
end
