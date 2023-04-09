defmodule Virtfs.FS do
  alias Virtfs.FS
  defstruct cwd: "/", files: %{}

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
