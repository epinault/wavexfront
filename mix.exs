defmodule Wavexfront.MixProject do
  use Mix.Project

  @version "0.9.2"

  def project do
    [
      app: :wavexfront,
      version: @version,
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: "Wavefront monitoring library. More at https://www.wavefront.com/",
      package: package(),
      deps: deps(),
      docs: docs(),
      name: "Wavexfront"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Wavexfront, []}
    ]
  end

  defp package() do
    [
      maintainers: ["Emmanuel Pinault"],
      licenses: ["ISC"],
      links: %{"GitHub" => "https://github.com/epinault/wavexfront"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hackney, "~> 1.1"},
      {:jason, "~> 1.0"},
      {:connection, "~> 1.0"},
      {:poolboy, "~> 1.5.1"},
      {:credo, "~> 1.0"},
      {:ex_doc, "~> 0.19", only: :dev}
    ]
  end

  defp docs do
    [
      main: "Wavexfront",
      source_ref: "v#{@version}",
      source_url: "https://github.com/epinault/wavexfront",
      extras: [""]
    ]
  end
end
