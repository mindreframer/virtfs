defmodule Virtfs do
  @moduledoc """
  Documentation for `Virtfs`.
  """

  def init(opts \\ []) do
    Virtfs.FS.init(opts)
  end
end
