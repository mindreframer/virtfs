defmodule Virtfs.MixProject do
  use Mix.Project

  def project do
    [
      app: :virtfs,
      version: "0.1.0",
      elixir: "~> 1.14",
      test_paths: ["test", "lib"],
      test_pattern: "*_test.exs",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Virtfs.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:typed_struct, "~> 0.3.0"},
      {:mneme, "~> 0.2", only: [:test]},
      {:erlmemfs, "~> 0.1.0"},
      {:test_iex, github: "mindreframer/test_iex", only: [:test, :dev]}
    ]
  end
end
