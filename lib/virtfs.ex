defmodule Virtfs do
  @moduledoc """
  Documentation for `Virtfs`.
  """
  use Virtfs.GenBehaviour
  alias Virtfs.FS

  def init(opts \\ []) do
    FS.init(opts)
  end
end
