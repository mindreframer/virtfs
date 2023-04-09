defmodule Virtfs.PathGlob do
  @moduledoc """
  Implements glob matching using the same semantics as `Path.wildcard/2`, but
  without any filesystem interaction.
  """

  alias Vendor.PathGlob.Compiler

  @doc """
  Returns whether or not `path` matches the `glob`.

  The glob is first parsed and compiled as a regular expression. If you're
  using the same glob multiple times in performance-critical code, consider
  using `compile/1` and caching the result.

  ## Examples

      iex> Virtfs.PathGlob.match?("{lib,test}/path_*.ex", "lib/path_glob.ex")
      true

      iex> Virtfs.PathGlob.match?("lib/*", "lib/.formatter.exs", match_dot: true)
      true
  """
  def match?(path, glob, opts \\ [])

  @spec match?(String.t(), String.t(), match_dot: boolean()) :: boolean()
  def match?(glob, path, opts) when is_binary(glob) do
    String.match?(path, Compiler.compile(glob, opts))
  end

  @spec match?(Regex.t(), String.t(), match_dot: boolean()) :: boolean()
  def match?(glob, path, _opts) when is_struct(glob, Regex) do
    String.match?(path, glob)
  end

  def compile(glob, opts \\ []), do: Compiler.compile(glob, opts)
end
