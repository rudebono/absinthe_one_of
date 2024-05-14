defmodule AbsintheOneOf.MixProject do
  use Mix.Project

  def project() do
    [
      app: :absinthe_one_of,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application() do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps() do
    [
      {:absinthe, "~> 1.7"}
    ]
  end
end
