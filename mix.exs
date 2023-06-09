defmodule Virtfs.MixProject do
  use Mix.Project
  @github_url "https://github.com/mindreframer/virtfs"
  @version "0.1.4"
  @description "Virtfs allows mock-FS operations, that can be applied on a real FS folder"

  def project do
    [
      app: :virtfs,
      source_url: @github_url,
      version: @version,
      description: @description,
      elixir: "~> 1.14",
      test_paths: ["test", "lib"],
      test_pattern: "*_test.exs",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex],
      mod: {Virtfs.Application, []}
    ]
  end

  defp package do
    [
      files: ~w(lib mix.exs README* CHANGELOG*),
      licenses: ["MIT"],
      links: %{
        "Github" => @github_url,
        "CHANGELOG" => "https://github.com/mindreframer/virtfs/blob/main/CHANGELOG.md"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_parsec, "~> 1.2.3", runtime: false},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:mneme, "~> 0.3.0", only: [:test]},
      {:maxo_test_iex, "~> 0.1", only: [:test]}
    ]
  end
end
