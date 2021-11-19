defmodule DataSchema.Map do
  @moduledoc """
  Provides helper functions for schemas where the input data is a map.
  """

  @doc """
  Allows us to just provide fields to a schema definition by partially applying the
  `DataSchema.Map` module. In essence it allows this:

      defmodule Blog do
        import DataSchema.Map, only: [map_schema: 2]

        map_schema([
          field: {:name, "name", &{:ok, to_string(&1)}}
        ])
      end

  Rather than this:

      defmodule Blog do
        import DataSchema, only: [data_schema: 2]

        data_schema([
          field: {:name, "name", &{:ok, to_string(&1)}}
        ], MapAccessor)
      end

  Which looks a bit nicer and reduces the surface area of future changes.
  """
  defmacro map_schema(fields) do
    quote do
      require DataSchema
      DataSchema.data_schema(unquote(fields), unquote(DataSchema.MapAccessor))
    end
  end
end
