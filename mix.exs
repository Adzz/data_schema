defmodule DataSchema.MixProject do
  use Mix.Project

  @version "0.2.3"
  @source_url "https://github.com/Adzz/data_schema"
  def project do
    [
      app: :data_schema,
      version: @version,
      elixir: "~> 1.12",
      package: package(),
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      description: description(),
      source_url: @source_url,
      docs: docs(),
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  # Because we have this the docs would leak (as they are generated in dev env).
  # To avoid that we set ex_docs to only appear in :docs env. That mean to publish
  # the library we must first manually generate the docs with MIX_ENV=docs mix hex.publish
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(:docs), do: ["lib"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description() do
    "Declarative descriptions of how to create a struct from different kinds of input data."
  end

  defp deps do
    [
      # This is added just so we can test the idea of an XML schema.
      {:sweet_xml, ">= 0.0.0", only: [:dev, :test]},
      {:ecto, ">= 0.0.0", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :docs, runtime: false}
    ]
  end

  defp package() do
    [
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  # See here for more: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html
  defp docs do
    [
      main: DataSchema,
      source_ref: "v#{@version}",
      extra_section: "GUIDES",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      extras: [
        "guides/introduction/Getting Started.md",
        "guides/introduction/XML Schemas.md"
        # do this when we implement the other.
        # "guides/introduction/Stopping to_struct when there is an error.md"
      ],
      groups_for_extras: [
        Introduction: ~r/guides\/introduction\/.?/
      ],
      groups_for_functions: [],
      groups_for_modules: [
        Accessors: [DataSchema.MapAccessor],
        Behaviours: [DataSchema.DataAccessBehaviour]
      ]
    ]
  end
end
