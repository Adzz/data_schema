defmodule DataSchema.DataAccessBehaviour do
  @moduledoc """
  Defines how `DataSchema.to_struct/2` should access data for each given field type.

  When we create a struct defined by the schema we will visit each struct field in turn
  and attempt to extract values from the source data. You tell the schema _how_ to
  extract that data by providing a module that implements this behaviour. Modules that
  implement this behaviour are implementing how to access data in the source for each kind
  of field.

  ### Examples

  To define a schema that consumes a map to create a struct you would first create a
  module that implements this behaviour like so:

      defmodule DataSchema.MapAccessor do
        @behaviour DataSchema.DataAccessBehaviour

        @impl true
        def field(data = %{}, field) do
          Map.get(data, field)
        end

        @impl true
        def list_of(data = %{}, field) do
          Map.get(data, field)
        end

        @impl true
        def has_one(data = %{}, field) do
          Map.get(data, field)
        end

        @impl true
        def has_many(data = %{}, field) do
          Map.get(data, field)
        end

        @impl true
        def aggregate(data = %{}, field) do
          Map.get(data, field)
        end
      end

  Then you would pass it into the schema definition:

      defmodule BlogPost do
        import DataSchema, only: [data_schema: 2]

        data_schema([
          field: {:content, "content", &{:ok, to_string(&1)}}
        ], DataSchema.MapAccessor)
      end

  When we call `DataSchema.to_struct/2` the functions in `DataSchema.MapAccessor` will be
  used to access the data from the source.

  DataSchema ships with the above example (see `DataSchema.MapAccessor`) and you can use
  `DataSchema.data_schema/1` to leverage it automatically.
  """

  @doc """
  The function that will be called when a `:field` field is encountered in the schema when
  we are turning some input data into a struct.
  """
  # Should these be okay tuples? What would we do in the case of error. I guess bail out.
  # It would mean non_null is not field level though.
  @callback field(any(), any()) :: any()
  @doc """
  The function that will be called when a `:list_of` field is encountered in the schema
  when we are turning some input data into a struct.
  """
  @callback list_of(any(), any()) :: any()
  @doc """
  The function that will be called when a `:has_one` field is encountered in the schema
  when we are turning some input data into a struct.
  """
  @callback has_one(any(), any()) :: any()
  @doc """
  The function that will be called when a `:has_one` field is encountered in the schema
  when we are turning some input data into a struct.
  """
  @callback has_many(any(), any()) :: any()
  @doc """
  The function that will be called when an `:aggregate` field is encountered in the schema
  when we are turning some input data into a struct.
  """
  @callback aggregate(any(), any()) :: any()
end
