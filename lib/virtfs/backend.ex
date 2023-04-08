defmodule Virtfs.Backend do
  alias Virtfs.File
  alias Virtfs.FS

  def write(%FS{} = fs, path, content) do
    full_path = Path.join(fs.cwd, path)

    file = Map.get(fs.files, full_path)

    cond do
      file == nil -> write_safe(fs, full_path, content)
      file.kind == :dir -> error(fs, :source_is_dir)
      true -> write_safe(fs, full_path, content)
    end
  end

  defp write_safe(fs, full_path, content) do
    dirpath = Path.dirname(full_path)
    fs = gen_full_hierarchy(fs, dirpath)
    file = %File{path: full_path, content: content}
    files = Map.put(fs.files, full_path, file)

    ok(update_fs(fs, :files, files))
  end

  def append(fs, path, content) do
    full_path = Path.join(fs.cwd, path)

    file = Map.get(fs.files, full_path)

    cond do
      file == nil -> write_safe(fs, full_path, content)
      file.kind == :dir -> error(fs, :source_is_dir)
      true -> write_safe(fs, full_path, file.content <> content)
    end
  end

  def append_line(fs, path, content) do
    append(fs, path, "\n" <> content)
  end

  def read(fs, path) do
    full_path = to_fullpath(fs.cwd, path)
    file = Map.get(fs.files, full_path)

    cond do
      file == nil -> error(fs, :not_found)
      file.kind == :dir -> error(fs, :source_is_dir)
      true -> ok(fs, file.content)
    end
  end

  def rm(fs, path) do
    full_path = to_fullpath(fs.cwd, path)
    file = Map.get(fs.files, full_path)

    {files, res} =
      cond do
        file == nil ->
          {fs.files, {:error, :source_not_found}}

        file.kind == :dir ->
          {fs.files, {:error, :source_is_dir}}

        file.kind == :file ->
          {Map.delete(fs.files, full_path), :ok}
      end

    case res do
      {:error, reason} -> error(fs, reason)
      :ok -> ok(update_fs(fs, :files, files))
    end
  end

  def ls(fs, path) do
    full_path = to_fullpath(fs.cwd, path)

    dir = Map.get(fs.files, full_path)

    cond do
      dir != nil && dir.kind == :dir ->
        paths = Map.keys(fs.files)
        regex = ls_regex(full_path)
        found = Enum.filter(paths, fn p -> Regex.match?(regex, p) end)
        ok(fs, found)

      true ->
        error(fs, :not_found)
    end
  def glob(fs, path) do
    {:ok, glob} = GlobEx.compile("#{fs.cwd}/#{path}")
    paths = Map.keys(fs.files)
    found = Enum.filter(paths, fn p -> GlobEx.match?(glob, p) end)
    ok(fs, found)
  end

  defp ls_regex("/") do
    with {:ok, regex} <- Regex.compile("^/[^/]+$") do
      regex
    end
  end

  defp ls_regex(full_path) do
    # everything with full_path at start + slash + non-slash chars at the end of path
    # takes only paths one level deeper then the given path
    with {:ok, regex} <- Regex.compile("^#{full_path}/[^/]+$") do
      regex
    end
  end

  def tree(fs, path) do
    full_path = to_fullpath(fs.cwd, path)
    paths = Map.keys(fs.files)
    regex = tree_regex(full_path)
    found = Enum.filter(paths, fn p -> Regex.match?(regex, p) end)

    ok(fs, found)
  end

  defp tree_regex("/") do
    {:ok, regex} = Regex.compile("^/.")
    regex
  end

  defp tree_regex(full_path) do
    {:ok, regex} = Regex.compile("^#{full_path}/.")
    regex
  end

  def rm_rf(fs, path) do
    full_path = to_fullpath(fs.cwd, path)
    paths = Map.keys(fs.files)
    regex = rm_rf_regex(full_path)
    found = Enum.filter(paths, fn p -> Regex.match?(regex, p) end)

    files =
      Enum.reduce(found, fs.files, fn p, files ->
        Map.delete(files, p)
      end)

    ok(update_fs(fs, :files, files))
  end

  defp rm_rf_regex(full_path) do
    with {:ok, regex} <- Regex.compile("^#{full_path}*") do
      regex
    end
  end

  def mkdir_p(fs, path) do
    full_path = to_fullpath(fs.cwd, path)
    file = Map.get(fs.files, full_path)

    fs =
      cond do
        file == nil -> gen_full_hierarchy(fs, full_path)
        true -> fs
      end

    ok(fs)
  end

  def cp(fs, src, dest) do
    full_src = to_fullpath(fs.cwd, src)
    full_dest = to_fullpath(fs.cwd, dest)

    file = Map.get(fs.files, full_src)

    {files, res} =
      cond do
        file == nil ->
          {fs.files, {:error, :source_not_found}}

        file.kind == :dir ->
          {fs.files, {:error, :source_is_dir}}

        file.kind == :file ->
          {Map.put(fs.files, full_dest, Map.put(file, :path, full_dest)), :ok}
      end

    case res do
      {:error, reason} -> error(fs, reason)
      :ok -> ok(update_fs(fs, :files, files))
    end
  end

  def cp_r(fs, src, dest) do
    full_src = to_fullpath(fs.cwd, src)
    full_dest = to_fullpath(fs.cwd, dest)

    file = Map.get(fs.files, full_src)

    cond do
      file == nil -> error(fs, :source_not_found)
      true -> cp_r_exists(fs, full_src, full_dest)
    end
  end

  defp cp_r_exists(fs, full_src, full_dest) do
    paths = Map.keys(fs.files)
    regex = rm_rf_regex(full_src)
    found = Enum.filter(paths, fn p -> Regex.match?(regex, p) end)

    fs =
      Enum.reduce(found, fs, fn path, fs ->
        file = Map.get(fs.files, path)
        new_path = String.replace_leading(file.path, full_src, full_dest)
        file = Map.put(file, :path, new_path)
        files = Map.put(fs.files, new_path, file)
        update_fs(fs, :files, files)
      end)

    ok(fs)
  end

  def rename(fs, src, dest) do
    full_src = to_fullpath(fs.cwd, src)
    full_dest = to_fullpath(fs.cwd, dest)
    file = Map.get(fs.files, full_src)

    {files, res} =
      cond do
        file == nil ->
          {fs.files, {:error, :source_not_found}}

        file.kind == :dir ->
          paths = Map.keys(fs.files)
          regex = rename_regex(full_src)
          found = Enum.filter(paths, fn p -> Regex.match?(regex, p) end)

          fs =
            Enum.reduce(found, fs, fn path, fs ->
              rename_existing(fs, path, full_src, full_dest)
            end)
            # also handle the src folder itself!
            |> rename_existing(full_src, full_src, full_dest)

          {fs.files, :ok}

        file.kind == :file ->
          files =
            Map.delete(fs.files, full_src) |> Map.put(full_dest, Map.put(file, :path, full_dest))

          {files, :ok}
      end

    case res do
      :ok -> ok(update_fs(fs, :files, files))
      {:error, reason} -> error(fs, reason)
    end
  end

  defp rename_existing(fs, path, full_src, full_dest) do
    file = Map.get(fs.files, path)
    path_dest = String.replace_leading(path, full_src, full_dest)
    dest_file = Map.put(file, :path, path_dest)

    files =
      fs.files
      |> Map.delete(path)
      |> Map.put(path_dest, dest_file)

    update_fs(fs, :files, files)
  end

  defp rename_regex("/") do
    {:ok, regex} = Regex.compile("^/.")
    regex
  end

  defp rename_regex(full_path) do
    {:ok, regex} = Regex.compile("^#{full_path}[\/]?.")
    regex
  end

  ## Nav
  def cd(fs, path) do
    full_path = to_fullpath(fs.cwd, path)
    file = Map.get(fs.files, full_path)

    cond do
      file == nil -> error(fs, :not_found)
      file.kind == :file -> error(fs, :not_dir)
      true -> ok(update_fs(fs, :cwd, full_path))
    end
  end

  def exists?(fs, path) do
    full_path = to_fullpath(fs.cwd, path)
    file = Map.get(fs.files, full_path)
    ok(fs, file != nil)
  end

  def dir?(fs, path) do
    full_path = to_fullpath(fs.cwd, path)
    file = Map.get(fs.files, full_path)

    res =
      cond do
        file == nil -> false
        file.kind == :dir -> true
        true -> false
      end

    ok(fs, res)
  end

  ## Path
  def expand(fs, path) do
    full_path = to_fullpath(fs.cwd, path)
    ok(fs, full_path)
  end

  def relative_to_cwd(fs, path) do
    full_path = to_fullpath(fs.cwd, path)
    res = Path.relative_to(full_path, fs.cwd)
    ok(fs, res)
  end

  ###
  ### HELPERS
  ###

  defp touch_dir(fs, path) do
    full_path = to_fullpath(fs.cwd, path)

    file = File.new_dir(full_path)
    files = Map.put(fs.files, full_path, file)
    ok(update_fs(fs, :files, files))
  end

  defp gen_full_hierarchy(fs, path) do
    full_path = to_fullpath(fs.cwd, path)
    parts = String.split(full_path, "/") |> Enum.reject(&(&1 == ""))

    {folders, _} =
      Enum.reduce(parts, {[], "/"}, fn part, {folders, last} ->
        {[Path.join(last, part) | folders], Path.join(last, part)}
      end)

    Enum.reduce(folders, fs, fn folder, fs ->
      {fs, :ok} = touch_dir(fs, folder)
      fs
    end)
  end

  defp to_fullpath(cwd, path) do
    Virtfs.Util.to_fullpath(cwd, path)
  end

  defp update_fs(fs, :files, files) do
    %FS{fs | files: files}
  end

  defp update_fs(fs, :cwd, path) do
    %FS{fs | cwd: path}
  end

  defp ok(fs), do: {fs, :ok}
  defp ok(fs, res), do: {fs, {:ok, res}}
  defp error(fs, res), do: {fs, {:error, res}}
end
