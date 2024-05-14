defmodule AbsintheOneOf.MixProject do
  use Mix.Project

  def project() do
    [
      app: :absinthe_one_of,
      version: "1.0.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  def application() do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps() do
    [
      {:absinthe, "~> 1.7"},
      {:absinthe_phoenix, "~> 2.0", only: :test, runtime: false},
      {:jason, "~> 1.4", only: :test},
      {:dialyxir, "~> 1.4", only: :test, runtime: false},
      {:credo, "~> 1.7", only: :test, runtime: false},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "Support an Input Union Type System Directive in Absinthe."
  end

  defp package() do
    [
      name: :absinthe_one_of,
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/rudebono/absinthe_one_of",
        "Docs" => "https://hexdocs.pm/absinthe_one_of"
      },
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*)
    ]
  end

  defp docs() do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end
