defmodule Feedly.MixProject do
  use Mix.Project

  def project do
    [
      app: :feedly,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: "https://github.com/osintowl/feedly",
      homepage_url: "https://github.com/osintowl/feedly"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:nimble_options, "~> 1.1"},
      {:typed_struct, "~> 0.3"},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  defp description do
    """
    Elixir client for the Feedly API with support for streams, search, articles, 
    threat intelligence (CVEs, threat actors, malware, IoCs, TTPs), and more.
    """
  end

  defp package do
    [
      name: "feedly",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      licenses: ["BSD-3-Clause"],
      links: %{
        "GitHub" => "https://github.com/osintowl/feedly"
      },
      maintainers: ["osintowl"]
    ]
  end

  defp docs do
    [
      main: "Feedly",
      extras: ["README.md"],
      source_url: "https://github.com/osintowl/feedly"
    ]
  end
end
