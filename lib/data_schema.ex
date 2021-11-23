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
          field: {:name, "name", &{:ok, to_string(&1)}}
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

  Depending on your input data type the path pointing to a value in it may need to be
  interpreted differently. For our example of a map input type, the "path" is really just
  a key on that input map. But there is still flexibility in how we use that key to access
  the value; we could use `Map.get/2` or `Map.fetch/2` for example. Additionally, for
  different input data types what the path looks like and what it means for how you access
  data can be different. Let's say your input data type was XML your path could be ".//MyNode",
  ie could be an xpath. In which case what you do with that xpath is going to be different
  from what you would do with a map key.

  DataSchema allows for different schemas to handle different input types AND allows for
  the same input type to be handled differently in different schemas.

  Finally when creating the struct we can choose to stop as soon as we find an error or to
  simply put whatever is returned from a casting function into the struct we are making.
  The latter approach encourages people to raise exceptions from their casting functions
  to halt the creation of the struct.

  ### Field Types

  There are 5 kinds of struct fields we can have:

  1. `field`     - The value will be a casted value from the source data.
  2. `list_of`   - The value will be a list of casted values created from the source data.
  3. `has_one`   - The value will be created from a nested data schema (so will be a struct)
  4. `has_many`  - The value will be created by casting a list of values into a data schema.
  (You end up with a list of structs defined by the provided schema). Similar to has_many in ecto
  5. `aggregate` - The value will a casted value formed from multiple bits of data in the source.

  ### Examples

  See the guides for more in depth examples but below you can see how we create a schema
  that will take a map of data and create a struct out of it. Given the following schema:

      defmodule Sandwich do
        require DataSchema

        DataSchema.data_schema([
          field: {:type, "the_type", &{:ok, String.upcase(&1)}},
          list_of: {:fillings, "the_fillings", &({:ok, String.downcase(&1["name"])})}
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
  @available_types [:field, :has_one, :has_many, :aggregate, :list_of]
  @non_null_error_message "Field was marked as not null but was found to be null."

  @doc """
  A macro that creates a data schema. By default all struct fields are required but you
  can specify that a field be optional by passing the correct option in. See the Options
  section below for more.

  ### Field Types

  There are 5 kinds of struct fields we can have:

  1. `field`     - The value will be a casted value from the source data.
  2. `list_of`   - The value will be a list of casted values created from the source data.
  3. `has_one`   - The value will be created from a nested data schema (so will be a struct)
  4. `has_many`  - The value will be created by casting a list of values into a data schema.
  (You end up with a list of structs defined by the provided schema). Similar to has_many in ecto
  5. `aggregate` - The value will a casted value formed from multiple bits of data in the source.

  ### Options

  Available options are:

    - `:optional?` - specifies whether or not the field in the struct should be included in
    the `@enforce_keys` for the struct. By default all fields are required but you can mark
    them as optional by setting this to `true`. This will also be checked when creating a
    struct with `DataSchema.to_struct/2` returning an error if the required field is null.

  For example:
      defmodule Sandwich do
        require DataSchema

        DataSchema.data_schema([
          field: {:type, "the_type", &{:ok, String.upcase(&1)}, optional?: true},
        ])
      end

  ### Examples

  See the guides for more in depth examples but below you can see how we create a schema
  that will take a map of data and create a struct out of it. Given the following schema:

      defmodule Sandwich do
        require DataSchema

        DataSchema.data_schema([
          field: {:type, "the_type", &{:ok, String.upcase.(&1)}},
          list_of: {:fillings, "the_fillings", &({:ok, String.downcase(&1["name"])})}
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
  defmacro data_schema(fields) do
    quote do
      @doc false
      def __data_schema_fields, do: unquote(fields)
      # __MODULE__ refers to the module that this macro is used in - ie the schema module.
      # We add a __data_accessor function so to_struct can call it, we default to a Map
      # accessor if no accessor is provided.
      if Module.has_attribute?(__MODULE__, :data_accessor) do
        @doc false
        def __data_accessor do
          @data_accessor
        end
      else
        @doc false
        def __data_accessor, do: DataSchema.MapAccessor
      end

      @enforce_keys Enum.reduce(
                      unquote(fields),
                      [],
                      fn
                        # Validates the shape of the fields at compile time.
                        {type, {_, _, _, _}}, _acc
                        when type not in unquote(@available_types) ->
                          message = """
                          Field #{inspect(type)} is not a valid field type.
                          Check the docs in DataSchema for more information on how fields should be written.
                          The available types are: #{inspect(unquote(@available_types))}
                          """

                          raise DataSchema.InvalidSchemaError, message: message

                        {type, {_, _, _}}, _acc
                        when type not in unquote(@available_types) ->
                          message = """
                          Field #{inspect(type)} is not a valid field type.
                          Check the docs in DataSchema for more information on how fields should be written.
                          The available types are: #{inspect(unquote(@available_types))}
                          """

                          raise DataSchema.InvalidSchemaError, message: message

                        {:aggregate, {_, schema, _, _}}, _acc
                        when not is_atom(schema) and not is_list(schema) ->
                          raise DataSchema.InvalidSchemaError, """
                          An :aggregate field should provide a nested schema to describe the data to be extracted.
                          This can be a module of another DataSchema or a list of schema fields:

                              defmodule Thing do
                                import DataSchema, only: [data_schema: 1]

                                @fields [
                                  field: {:date, "date", &Date.from_iso8601/1},
                                  field: {:time, "time", &Time.from_iso8601/1}
                                ]

                                data_schema([
                                  aggregate: {:datetime, @fields, NaiveDateTime.new(&1.date, &1.time)}
                                ])
                              end

                          Or:

                              defmodule Thing do
                                import DataSchema, only: [data_schema: 1]

                                defmodule DateTime do
                                  import DataSchema, only: [data_schema: 1]

                                  data_schema([
                                    field: {:date, "date", &Date.from_iso8601/1},
                                    field: {:time, "time", &Time.from_iso8601/1}
                                  ])
                                end

                                data_schema([
                                  aggregate: {:datetime, DateTime, &NaiveDateTime.new(&1.date, &1.time)}
                                ])
                              end

                          Provided schema: #{inspect(schema)}
                          """

                        {:aggregate, {_, schema, _}}, _acc
                        when not is_atom(schema) and not is_list(schema) ->
                          raise DataSchema.InvalidSchemaError, """
                          An :aggregate field should provide a nested schema to describe the data to be extracted.
                          This can be a module of another DataSchema or a list of schema fields:

                              defmodule Thing do
                                import DataSchema, only: [data_schema: 1]

                                @fields [
                                  field: {:date, "date", &Date.from_iso8601/1},
                                  field: {:time, "time", &Time.from_iso8601/1}
                                ]

                                data_schema([
                                  aggregate: {:datetime, @fields, NaiveDateTime.new(&1.date, &1.time)}
                                ])
                              end

                          Or:

                              defmodule Thing do
                                import DataSchema, only: [data_schema: 1]

                                defmodule DateTime do
                                  import DataSchema, only: [data_schema: 1]

                                  data_schema([
                                    field: {:date, "date", &Date.from_iso8601/1},
                                    field: {:time, "time", &Time.from_iso8601/1}
                                  ])
                                end

                                data_schema([
                                  aggregate: {:datetime, DateTime, &NaiveDateTime.new(&1.date, &1.time)}
                                ])
                              end

                          Provided schema: #{inspect(schema)}
                          """

                        {type, {_, _, module, _}}, _acc
                        when type in [:has_one, :has_many] and not is_atom(module) and
                               not is_list(module) ->
                          message = """
                          #{type} fields require a DataSchema module as their casting function:

                              data_schema([
                                #{type}: {:foo, "path", Foo}
                                #                        ^^
                                # Should be a DataSchema module
                              ])

                          Or an inline list of fields like so:

                              @foo_fields [
                                field: {:bar, "bar", &{:ok, to_string(&1)}}
                              ]

                              data_schema([
                                #{type}: {:foo, "path", @foo_fields}
                                #                          ^^
                                # Or a list of fields inline.
                              ])

                          You provided the following as a schema: #{inspect(module)}.
                          Ensure you haven't used the wrong field type.
                          """

                          raise DataSchema.InvalidSchemaError, message: message

                        {type, {_, _, module}}, _acc
                        when type in [:has_one, :has_many] and not is_atom(module) and
                               not is_list(module) ->
                          message = """
                          #{type} fields require a DataSchema module as their casting function:

                              data_schema([
                                #{type}: {:foo, "path", Foo}
                                #                        ^^
                                # Should be a DataSchema module
                              ])

                          Or an inline list of fields like so:

                              @foo_fields [
                                field: {:bar, "bar", &{:ok, to_string(&1)}}
                              ]

                              data_schema([
                                #{type}: {:foo, "path", @foo_fields}
                                #                          ^^
                                # Or a list of fields inline.
                              ])

                          You provided the following as a schema: #{inspect(module)}.
                          Ensure you haven't used the wrong field type.
                          """

                          raise DataSchema.InvalidSchemaError, message: message

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
                  {_, {field, _, _}} when not is_atom(field) ->
                    message = """
                    The provided struct keys must be atoms. See docs for more information:

                        data_schema([
                          field: {:foo, "foo", &{:ok, &1}}
                        #          ^^^
                        #   must be an atom!
                        ])
                    """

                    raise DataSchema.InvalidSchemaError, message: message

                  {_, {field, _, _, _}} when not is_atom(field) ->
                    message = """
                    The provided struct keys must be atoms. See docs for more information:

                        data_schema([
                          field: {:foo, "foo", &{:ok, &1}}
                        #          ^^^
                        #   must be an atom!
                        ])
                    """

                    raise DataSchema.InvalidSchemaError, message: message

                  {_, {field, _, _}} ->
                    field

                  {_, {field, _, _, _}} ->
                    field

                  _ ->
                    raise DataSchema.InvalidSchemaError
                end)
    end
  end

  @doc """
  Accepts an data schema module and some source data and attempts to create the struct
  defined in the schema from the source data recursively.

  We essentially visit each field in the schema and extract the data the field points to
  from the sauce data, passing it to the field's casting function before setting the
  result of that as the value on the struct.

  This function takes a simple approach to creating the struct - whatever you return from
  a casting function will be set as the value of the struct field. You should raise if
  you want casting to fail.

  ### Examples

      data = %{ "spice" => "enables space travel" }

      defmodule Foo do
        require DataSchema

        DataSchema.data_schema(
          field: {:a_rocket, "spice", &({:ok, &1})}
        )
      end

      DataSchema.to_struct(data, Foo)
      # => Outputs the following:
      %Foo{a_rocket: "enables space travel"}
  """
  def to_struct(data, %schema{}) do
    to_struct(data, schema, [])
  end

  def to_struct(data, schema) do
    to_struct(data, schema, [])
  end

  def to_struct(data, %schema{}, opts) do
    to_struct(data, schema, opts)
  end

  def to_struct(data, schema, opts) when is_atom(schema) do
    if !function_exported?(schema, :__data_schema_fields, 0) do
      raise "Provided schema is not a valid DataSchema: #{inspect(schema)}"
    end

    fields = schema.__data_schema_fields()
    accessor = schema.__data_accessor()
    struct = struct(schema, %{})
    to_struct(data, struct, fields, accessor, opts)
  end

# defmodule DateAndTime do
#   defstruct [:date, :time]
# end

# data = %{"date" => "1", "time" => "2"}
# fields = [
#   field: {:date, "date", &Date.from_iso8601/1},
#   field: {:time, "time", &Time.from_iso8601/1}
# ]
# accessor = MapAccessor
# struct_or_schema = DateAndTime

# Now there is the Q of should we default the accessor and opts... We'd need a map input
# to not clash arity though. or a new name for this like
# "schemaless_to_struct" or "to_existing_struct"
  def to_struct(data, struct, fields, accessor) do
    to_struct(data, struct, fields, accessor, [])
  end

  def to_struct(data, struct, fields, accessor, opts) do
    # Right now we fail as soon as we get an error. If this error is nested deep then we
    # generate a recursive error that points to the value that caused it. We can imagine
    # instead "collecting" errors - meaning continuing with struct creation to gather up
    # all possible errors that will happen on struct creation. How to do this boggles the
    # mind a bit. But we'd need an option I do know that....
    # collect_errors? = Keyword.get(opts, :collect_errors, false)

    Enum.reduce_while(fields, struct, fn
      {:aggregate, {field, schema_mod, cast_fn, field_opts}}, struct when is_atom(schema_mod) ->
        nullable? = Keyword.get(field_opts, :optional?, false)
        fields = schema_mod.__data_schema_fields()
        accessor = schema_mod.__data_accessor()
        aggregate = struct(schema_mod, %{})
        aggregate(fields, accessor, data, opts, field, cast_fn, aggregate, struct, nullable?)

      {:aggregate, {field, schema_mod, cast_fn}}, struct when is_atom(schema_mod) ->
        fields = schema_mod.__data_schema_fields()
        accessor = schema_mod.__data_accessor()
        aggregate = struct(schema_mod, %{})
        aggregate(fields, accessor, data, opts, field, cast_fn, aggregate, struct, false)

      {:aggregate, {field, fields, cast_fn, field_opts}}, struct when is_list(fields) ->
        nullable? = Keyword.get(field_opts, :optional?, false)
        aggregate(fields, accessor, data, opts, field, cast_fn, %{}, struct, nullable?)

      {:aggregate, {field, fields, cast_fn}}, struct when is_list(fields) ->
        aggregate(fields, accessor, data, opts, field, cast_fn, %{}, struct, false)

      {field_type, {field, paths, cast_fn, field_opts}}, struct ->
        nullable? = Keyword.get(field_opts, :optional?, false)
        process_field({field_type, {field, paths, cast_fn}}, struct, nullable?, accessor, data)

      {_, {_, _, _}} = field, struct ->
        # By default fields are not nullable.
        nullable? = false
        process_field(field, struct, nullable?, accessor, data)
    end)
    |> case do
      :error -> :error
      {:error, error_message} -> {:error, error_message}
      struct -> {:ok, struct}
    end
  end

  defp process_field({:field, {field, path, cast_fn}}, struct, nullable?, accessor, data) do
    case call_cast_fn(cast_fn, accessor.field(data, path)) do
      {:ok, nil} ->
        if nullable? do
          {:cont, Map.put(struct, field, nil)}
        else
          # Instead of halt we would have to
          {:halt, {:error, null_error(%DataSchema.Errors{}, field)}}
        end

      {:ok, value} ->
        {:cont, Map.put(struct, field, value)}

      {:error, _} = error ->
        {:halt, error}

      :error ->
        {:halt, :error}
    end
  end

  defp process_field({:has_one, {field, path, cast_module}}, struct, nullable?, accessor, data) do
    case accessor.has_one(data, path) do
      nil ->
        if nullable? do
          # Should we still call cast fn? There is no cast to happen here as cast is to_struct
          # which happens automatically.
          {:cont, Map.put(struct, field, nil)}
        else
          {:halt, {:error, null_error(%DataSchema.Errors{}, field)}}
        end

      value ->
        case to_struct(value, cast_module) do
          # It's not possible for to_struct to return nil so we don't handle that case here
          {:ok, value} -> {:cont, Map.put(struct, field, value)}
          {:error, _} = error -> {:halt, error}
          :error -> {:halt, :error}
        end
    end
  end

  defp process_field(
         {:has_many, {field, path, cast_module}},
         struct,
         nullable?,
         accessor,
         data
       ) do
    case accessor.has_many(data, path) do
      nil ->
        if nullable? do
          {:cont, Map.put(struct, field, nil)}
        else
          {:halt, {:error, null_error(%DataSchema.Errors{}, field)}}
        end

      data ->
        data
        |> Enum.reduce_while([], fn datum, acc ->
          # It's not possible for to_struct to return nil so we don't worry about it here.
          case to_struct(datum, cast_module) do
            {:ok, struct} -> {:cont, [struct | acc]}
            {:error, _} = error -> {:halt, error}
            :error -> {:halt, :error}
          end
        end)
        |> case do
          {:error, _} = error ->
            {:halt, error}

          :error ->
            {:halt, :error}

          relations when is_list(relations) ->
            {:cont, %{struct | field => :lists.reverse(relations)}}
        end
    end
  end

  defp process_field({:list_of, {field, path, cast_module}}, struct, nullable?, accessor, data) do
    case accessor.list_of(data, path) do
      nil ->
        if nullable? do
          {:cont, Map.put(struct, field, nil)}
        else
          {:halt, {:error, null_error(%DataSchema.Errors{}, field)}}
        end

      data ->
        data
        |> Enum.reduce_while([], fn datum, acc ->
          case call_cast_fn(cast_module, datum) do
            {:ok, nil} ->
              if nullable? do
                # Do we add nil or do we remove them? a list of nils seeeeems bad. But is it
                # better to not remove information...?
                # {:cont, [nil | acc]}

                {:cont, acc}
              else
                {:halt, {:error, "Got null for a field that can't be null."}}
              end

            {:ok, value} ->
              {:cont, [value | acc]}

            {:error, _} = error ->
              {:halt, error}

            :error ->
              {:halt, :error}
          end
        end)
        |> case do
          {:error, error} ->
            {:halt, {:error, %DataSchema.Errors{errors: [{field, error}]}}}

          :error ->
            {:halt, :error}

          relations when is_list(relations) ->
            {:cont, %{struct | field => :lists.reverse(relations)}}
        end
    end
  end

  defp aggregate(fields, accessor, data, opts, field, cast_fn, aggregate, parent, nullable?) do
    case to_struct(data, aggregate, fields, accessor, opts) do
      :error ->
        {:halt, :error}

      {:error, error} ->
        {:halt, {:error, %DataSchema.Errors{errors: [{field, error}]}}}

      {:ok, values_map} ->
        case call_cast_fn(cast_fn, values_map) do
          {:ok, nil} ->
            if nullable? do
              {:cont, Map.put(parent, field, nil)}
            else
              {:halt, {:error, null_error(%DataSchema.Errors{}, field)}}
            end

          {:ok, value} ->
            {:cont, Map.put(parent, field, value)}

          {:error, error} ->
            {:halt, {:error, %DataSchema.Errors{errors: [{field, error}]}}}

          :error ->
            {:halt, :error}
        end
    end
  end

  defp null_error(error, field) do
    DataSchema.Errors.add_error(error, {field, @non_null_error_message})
  end

  # This just lets us use either a module name for the data type OR a one arity fn.
  defp call_cast_fn(module, value) when is_atom(module), do: module.cast(value)
  defp call_cast_fn(fun, value) when is_function(fun, 1), do: fun.(value)
end
