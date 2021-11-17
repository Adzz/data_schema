defmodule DataSchema do
  @moduledoc """
  DataSchemas are declarative specifications of how to create structs from some kind of
  data source. For example you can define a schema that knows how to turn an elixir map
  into a struct, casting all of the values as it goes. Alternatively you can set up a
  schema to ingest XML data and create structs from the values inside the XML.

  Below is an example of a simple schema:

      defmodule Blog do
        import DataSchema, only: [data_schema: 1]

        data_schema([
          field: {:name, "name", &to_string/1}
        ])
      end

  This says we will create a struct with a `:name` key and will get the value for that key
  from under the `"name"` key in the source data. That value will be passed to `to_string/1`
  and the result of that function will end up as the value under `:name` in the resulting
  struct.

  In general this is the format for a field:

      field {:content, "text", &cast_string/1}
      #  ^         ^      ^              ^
      # field type |      |              |
      # struct key name   |              |
      #    path to data in the source    |
      #                           casting function

  ### Field Types

  There are 4 kinds of struct fields we can have:

  1. `field`     - The value will be a casted value from the source data.
  2. `list_of`   - The value will be a list of casted values created from the source data.
  3. `has_one`   - The value will be created from a nested data schema (so will be a struct)
  4. `aggregate` - The value will a casted value formed from multiple bits of data in the source.

  ### Examples

  See the guides for more in depth examples but below you can see how we create a schema
  that will take a map of data and create a struct out of it. Given the following schema:

      defmodule Sandwich do
        require DataSchema

        DataSchema.data_schema([
          field: {:type, "the_type", &String.upcase/1},
          list_of: {:fillings, "the_fillings", &(String.downcase(&1["name"]))}
        ])
      end

      input_data = %{
        "the_type" => "fake steak",
        "the_fillings" => [
          %{"name" => "fake stake", "good?" => true},
          %{"name" => "SAUCE"},
          %{"name" => "sweetcorn"},
        ]
      }

      DataSchema.to_struct(input_data, Sandwich)
      # outputs the following:
      %Sandwich{
        type: "FAKE STEAK",
        fillings: ["fake stake", "sauce", "sweetcorn"],
      }
  """

  @doc """
  Defines a data schema with the provided fields. Uses the default `DataSchema.MapAccessor`
  as the accessor, meaning it will expect the source data to be an elixir map and will
  use `Map.get/2` to access the required values in the source data.

  See `DataSchema.data_schema/2` for more details on what fields should look like.
  """
  defmacro data_schema(fields) do
    quote do
      DataSchema.data_schema(unquote(fields), DataSchema.MapAccessor)
    end
  end

  @doc """
  A macro that creates a data schema. By default all struct fields are required but you
  can specify that a field be optional by passing the correct option in. See the Options
  section below for more.

  ### Field Types

  There are 4 kinds of struct fields we can have:

  1. `field`     - The value will be a casted value from the source data.
  2. `list_of`   - The value will be a list of casted values created from the source data.
  3. `has_one`   - The value will be created from a nested data schema (so will be a struct)
  4. `aggregate` - The value will a casted value formed from multiple bits of data in the source.

  ### Options

  Available options are:

    - `:optional?` - specifies whether or not the field in the struct should be included in
    the `@enforce_keys` for the struct. By default all fields are required but you can mark
    them as optional by setting this to `true`.

  ### Examples

  See the guides for more in depth examples but below you can see how we create a schema
  that will take a map of data and create a struct out of it. Given the following schema:

      defmodule Sandwich do
        require DataSchema

        DataSchema.data_schema([
          field: {:type, "the_type", &String.upcase/1},
          list_of: {:fillings, "the_fillings", &(String.downcase(&1["name"]))}
        ])
      end

      input_data = %{
        "the_type" => "fake steak",
        "the_fillings" => [
          %{"name" => "fake stake", "good?" => true},
          %{"name" => "SAUCE"},
          %{"name" => "sweetcorn"},
        ]
      }

      DataSchema.to_struct(input_data, Sandwich)
      # outputs the following:
      %Sandwich{
        type: "FAKE STEAK",
        fillings: ["fake stake", "sauce", "sweetcorn"],
      }
  """
  defmacro data_schema(fields, data_accessor) do
    quote do
      @doc false
      def __data_schema_fields, do: unquote(fields)
      @doc false
      def __data_accessor, do: unquote(data_accessor)

      @enforce_keys Enum.reduce(
                      unquote(fields),
                      [],
                      fn
                        # Validates the shape of the fields at compile time.
                        {type, {_, _xpath, _cast_fn, _opts}}, acc
                        when type not in [:field, :has_one, :aggregate, :list_of] ->
                          raise DataSchema.InvalidSchemaError,
                                "Field #{inspect(type)} is not a valid field type.\n" <>
                                  "Check the docs in DataSchema for more " <>
                                  "information on how fields should be written."

                        {type, {_, _xpath, _cast_fn}}, acc
                        when type not in [:field, :has_one, :aggregate, :list_of] ->
                          raise DataSchema.InvalidSchemaError,
                                "Field #{inspect(type)} is not a valid field type.\n" <>
                                  "Check the docs in DataSchema for more " <>
                                  "information on how fields should be written."

                        {_, {field, _, _, opts}}, acc ->
                          # By default fields are required but they can be marked as optional.
                          if Keyword.get(opts, :optional?, false) do
                            acc
                          else
                            [field | acc]
                          end

                        # If no options are provided the field is enforced.
                        {_, {field, _, _}}, acc ->
                          [field | acc]

                        _, _ ->
                          raise DataSchema.InvalidSchemaError
                      end
                    )
      defstruct Enum.map(unquote(fields), fn
                  {_, {field, _xpath, _cast_fn}} -> field
                  {_, {field, _xpath, _cast_fn, _opts}} -> field
                  _ -> raise DataSchema.InvalidSchemaError
                end)
    end
  end

  @doc """
  Accepts an data schema module and some source data and attempts to create the struct
  defined in the schema from the source data recursively.

  Right now this takes a simple approach to creating the struct - whatever you return from
  a casting function will be set as the value of the struct field. You should raise if
  you want casting to fail.

  That means we don't do anything to check at runtime that the type of the field is what
  you specified it should be.

  ### Examples

      data = %{ "spice" => "enables space travel" }

      defmodule Foo do
        require DataSchema

        DataSchema.data_schema(
          [field: {:a_rocket, "spice", & &1}],
          MapAccessor
        )
      end

      DataSchema.to_struct(data, Foo)
  """
  def to_struct(data, %schema{}) do
    to_struct(data, schema)
  end

  def to_struct(data, schema) do
    accessor = schema.__data_accessor()

    Enum.reduce(schema.__data_schema_fields(), struct(schema, %{}), fn
      {:aggregate, {field, %{} = paths, cast_fn, _opts}}, struct ->
        values_map =
          Map.new(paths, fn {key, path} ->
            {key, accessor.aggregate(data, path)}
          end)

        %{struct | field => call_cast_fn(cast_fn, values_map)}

      {:aggregate, {field, %{} = paths, cast_fn}}, struct ->
        values_map =
          Map.new(paths, fn {key, path} ->
            {key, accessor.aggregate(data, path)}
          end)

        %{struct | field => call_cast_fn(cast_fn, values_map)}

      {:field, {field, path, cast_fn, _opts}}, struct ->
        %{struct | field => call_cast_fn(cast_fn, accessor.field(data, path))}

      {:field, {field, path, cast_fn}}, struct ->
        %{struct | field => call_cast_fn(cast_fn, accessor.field(data, path))}

      {:has_one, {field, path, cast_module, _opts}}, struct ->
        value = to_struct(accessor.has_one(data, path), cast_module)
        %{struct | field => value}

      {:has_one, {field, path, cast_module}}, struct ->
        value = to_struct(accessor.has_one(data, path), cast_module)
        %{struct | field => value}

      {:list_of, {field, path, cast_module, _opts}}, struct ->
        relations = Enum.map(accessor.list_of(data, path), &call_cast_fn(cast_module, &1))
        %{struct | field => relations}

      {:list_of, {field, path, cast_module}}, struct ->
        relations = Enum.map(accessor.list_of(data, path), &call_cast_fn(cast_module, &1))
        %{struct | field => relations}
    end)
  end

  # This just lets us use either a module name for the data type OR a one arity fn.
  defp call_cast_fn(module, value) when is_atom(module), do: module.cast(value)
  defp call_cast_fn(fun, value) when is_function(fun, 1), do: fun.(value)
end
