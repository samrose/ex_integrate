defmodule ExIntegrate.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_integrate,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExIntegrate.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:jason, "~> 1.2"},
      {:libgraph, "~> 0.13"},
      {:rambo, "~> 0.3"}
    ]
  end
end
