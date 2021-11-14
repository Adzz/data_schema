defmodule DataSchema do
  @moduledoc """
  Documentation for `DataSchema`.
  """

  @doc """
  A macro that creates a data schema.
  """
  defmacro data_schema(fields, data_accessor) do
    quote do
      def __data_schema_fields, do: unquote(fields)
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
  defined in the schema from the source data.

  Right now this takes a simple approach to creating the struct - whatever you return from
  a casting function will be set as the value of the struct field. You should raise if
  you want casting to fail.

  That means we don't do anything to check at runtime that the type of the field is what
  you specified it should be.

  In the future we could change this to collect errors or to return errors in the case of
  failed casting. Additionally we do not enforce not null, so if you wish to raise when
  a field is nil you should handle that in the casting function used.


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
