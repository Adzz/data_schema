defmodule DataSchema.MapAccessor do
  @moduledoc """
  Defines a way to use elixir maps as an input data source. This will `Map.get` the fields
  from the source data, meaning it will return nil in the case of the key being missing.
  """
  @behaviour DataSchema.DataAccessBehaviour

  @impl true
  def field(data, field) do
    Map.get(data, field)
  end

  @impl true
  def list_of(data, field) do
    Map.get(data, field)
  end

  @impl true
  def has_one(data, field) do
    Map.get(data, field)
  end

  @impl true
  def aggregate(data, field) do
    Map.get(data, field)
  end

  @doc """
  Allows us to just provide fields to a schema definition by partially applying the
  DataSchema.MapAccessor module. In essence it allows this:

      defmodule Blog do
        import DataSchema.MapAccessor, only: [map_schema: 2]

        map_schema([
          field: {:name, "name", &to_string/1}
        ])
      end

  Rather than this:

      defmodule Blog do
        import DataSchema, only: [data_schema: 2]

        data_schema([
          field: {:name, "name", &to_string/1}
        ], MapAccessor)
      end

  Which looks a bit nicer and reduces the surface area of future changes.
  """
  defmacro map_schema(fields) do
    quote do
      require DataSchema
      DataSchema.data_schema(unquote(fields), DataSchema.MapAccessor)
    end
  end
end
