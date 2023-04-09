defmodule Vendor.PathGlob.Compiler do
  import Virtfs.PathGlob.Parser

  require NimbleParsec
  NimbleParsec.defparsec(:parse, glob(), inline: true)

  @doc """
  Compiles `glob` to a `Regex`.

  Raises `ArgumentError` if `glob` is invalid.

  ## Examples

      iex> Virtfs.PathGlob.compile("{lib,test}/*")
      ~r{^(lib|test)/([^\\./]|(?<=[^/])\\.)*$}

      iex> Virtfs.PathGlob.compile("{lib,test}/path_*.ex", match_dot: true)
      ~r{^(lib|test)/path_[^/]*\\.ex$}
  """
  @spec compile(String.t(), match_dot: boolean()) :: Regex.t()
  def compile(glob, opts \\ []) do
    case parse(glob) do
      {:ok, [parse_tree], "", _, _, _} ->
        regex =
          parse_tree
          |> transform(Keyword.get(opts, :match_dot, false))
          |> Regex.compile!()

        inspect(
          %{
            glob: glob,
            regex: regex,
            parse_tree: parse_tree
          },
          pretty: true
        )

        regex

      {:error, _, _, _, _, _} = _error ->
        raise ArgumentError, "failed to parse '#{glob}'"
    end
  end

  defp transform_join(list, match_dot?, joiner \\ "") when is_list(list) do
    list
    |> Enum.map(&transform(&1, match_dot?))
    |> Enum.join(joiner)
  end

  defp transform(token, match_dot?) do
    case token do
      {:glob, terms} ->
        "^#{transform_join(terms, match_dot?)}$"

      {:literal, items} ->
        items
        |> Enum.join()
        |> Regex.escape()

      {:question, _} ->
        any_single(match_dot?)

      {:double_star_slash, _} ->
        pattern = "(#{any_single(match_dot?)}+/)*"

        if match_dot? do
          pattern
        else
          "#{pattern}(?!\\.)"
        end

      {:double_star, _} ->
        "(#{any_single(match_dot?)}+/)*#{any_single(match_dot?)}+"

      {:star, _} ->
        "#{any_single(match_dot?)}*"

      {:alternatives, items} ->
        choice(items, match_dot?)

      {:alternatives_item, items} ->
        transform_join(items, match_dot?)

      {:character_list, items} ->
        transform_join(items, match_dot?, "|")

      {:character_range, [start, finish]} ->
        "[#{transform(start, match_dot?)}-#{transform(finish, match_dot?)}]"

      {:character_class, items} ->
        choice(items, match_dot?)
    end
  end

  defp any_single(match_dot?) do
    if match_dot? do
      "[^/]"
    else
      "([^\\./]|(?<=[^/])\\.)"
    end
  end

  defp choice(items, match_dot?) do
    "(#{transform_join(items, match_dot?, "|")})"
  end
end
