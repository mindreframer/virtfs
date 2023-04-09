defmodule Virtfs.File do
  @type kind :: :file | :dir

  defstruct kind: :file, content: "", path: nil

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
