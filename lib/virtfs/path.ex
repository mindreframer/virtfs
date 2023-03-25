defmodule Virtfs.Path do
  # expand_dot the given path by expanding "..", "." and "~".
  def expand_dot(<<"/", rest::binary>>), do: "/" <> do_expand_dot(rest)

  def expand_dot(<<letter, ":/", rest::binary>>) when letter in ?a..?z,
    do: <<letter, ":/">> <> do_expand_dot(rest)

  def expand_dot(path), do: do_expand_dot(path)

  def do_expand_dot(path), do: do_expand_dot(:binary.split(path, "/", [:global]), [])
  def do_expand_dot([".." | t], [_, _ | acc]), do: do_expand_dot(t, acc)
  def do_expand_dot([".." | t], []), do: do_expand_dot(t, [])
  def do_expand_dot(["." | t], acc), do: do_expand_dot(t, acc)
  def do_expand_dot([h | t], acc), do: do_expand_dot(t, ["/", h | acc])
  def do_expand_dot([], []), do: ""
  def do_expand_dot([], ["/" | acc]), do: IO.iodata_to_binary(:lists.reverse(acc))
end
