defmodule DataSchema.MixProject do
  use Mix.Project

  def project do
    [
      app: :data_schema,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # This is added just so we can test the idea of an XML schema.
      {:sweet_xml, ">= 0.0.0", only: [:dev, :test]}
    ]
  end
end
