defmodule Virtfs.File do
  @type kind :: :file | :folder

  use TypedStruct

  typedstruct do
    @typedoc "A File"

    field(:kind, kind, default: :file)
    field(:content, String.t(), default: "")
    field(:path, String.t(), enforce: true)
  end
end
