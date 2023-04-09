Mix.start()
Mix.shell(Mix.Shell.Process)
Application.put_env(:mix, :colors, enabled: false)

# Logger.remove_backend(:console)
# Application.put_env(:logger, :backends, [])

os_exclude = if match?({:win32, _}, :os.type()), do: [unix: true], else: [windows: true]
epmd_exclude = if match?({:win32, _}, :os.type()), do: [epmd: true], else: []

{line_exclude, line_include} =
  if line = System.get_env("LINE"), do: {[:test], [line: line]}, else: {[], []}

ExUnit.start(
  trace: !!System.get_env("TRACE"),
  exclude: epmd_exclude ++ os_exclude ++ line_exclude,
  include: line_include
)

defmodule MixTest.Case do
  use ExUnit.CaseTemplate

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

      for {app, _, _} <- Application.loaded_applications(), app not in @apps do
        Application.stop(app)
        Application.unload(app)
      end

      :ok
    end)

    :ok
  end

  defp remove_colons(term) do
    term
    |> to_string()
    |> String.replace(":", "")
  end
end
