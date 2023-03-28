Mix.start()
Mix.shell(Mix.Shell.Process)
Application.put_env(:mix, :colors, enabled: false)

Logger.remove_backend(:console)
Application.put_env(:logger, :backends, [])

os_exclude = if match?({:win32, _}, :os.type()), do: [unix: true], else: [windows: true]
epmd_exclude = if match?({:win32, _}, :os.type()), do: [epmd: true], else: []
git_exclude = if Mix.SCM.Git.git_version() <= {1, 7, 4}, do: [git_sparse: true], else: []

{line_exclude, line_include} =
  if line = System.get_env("LINE"), do: {[:test], [line: line]}, else: {[], []}

ExUnit.start(
  trace: !!System.get_env("TRACE"),
  exclude: epmd_exclude ++ os_exclude ++ git_exclude ++ line_exclude,
  include: line_include
)

# Clear environment variables that may affect tests
System.delete_env("http_proxy")
System.delete_env("https_proxy")
System.delete_env("HTTP_PROXY")
System.delete_env("HTTPS_PROXY")
System.delete_env("MIX_ENV")
System.delete_env("MIX_TARGET")

defmodule MixTest.Case do
  use ExUnit.CaseTemplate

  defmodule Sample do
    def project do
      [app: :sample, version: "0.1.0", aliases: [sample: "compile"]]
    end

    def application do
      Process.get({__MODULE__, :application}) || []
    end
  end

  using do
    quote do
      import MixTest.Case
    end
  end

  @apps Enum.map(Application.loaded_applications(), &elem(&1, 0))

  setup do
    on_exit(fn ->
      Application.start(:logger)
      Mix.env(:dev)
      Mix.target(:host)
      Mix.Task.clear()
      Mix.Shell.Process.flush()
      Mix.State.clear_cache()
      Mix.ProjectStack.clear_stack()
      delete_tmp_paths()

      for {app, _, _} <- Application.loaded_applications(), app not in @apps do
        Application.stop(app)
        Application.unload(app)
      end

      :ok
    end)

    :ok
  end

  def tmp_path do
    Path.expand("../tmp", __DIR__)
  end

  def tmp_path(extension) do
    Path.join(tmp_path(), remove_colons(extension))
  end

  defp remove_colons(term) do
    term
    |> to_string()
    |> String.replace(":", "")
  end

  defp delete_tmp_paths do
    tmp = tmp_path() |> String.to_charlist()
    for path <- :code.get_path(), :string.str(path, tmp) != 0, do: :code.del_path(path)
  end
end

## Set up globals

home = MixTest.Case.tmp_path(".home")
File.mkdir_p!(home)
System.put_env("HOME", home)

mix = MixTest.Case.tmp_path(".mix")
File.mkdir_p!(mix)
System.put_env("MIX_HOME", mix)

System.delete_env("XDG_DATA_HOME")
System.delete_env("XDG_CONFIG_HOME")
