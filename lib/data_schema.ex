defmodule DataSchema do
  @external_resource Path.expand("./README.md")
  @moduledoc File.read!(Path.expand("./README.md"))
             |> String.split("<!-- README START -->")
             |> Enum.at(1)
             |> String.split("<!-- README END -->")
             |> List.first()

  @available_types [:field, :has_one, :has_many, :aggregate, :list_of]

  @doc """
  Accepts a the module of a compile time schema and will expand it into a runtime schema
  recursively. This can be useful for tooling around generating schemas or for schema
  reflection.
  """
  def to_runtime_schema(schema) when is_atom(schema) do
    if Code.ensure_loaded?(schema) &&
         !function_exported?(schema, :__data_schema_fields, 0) do
      raise "Provided schema is not a valid DataSchema: #{inspect(schema)}"
    end

    to_runtime_schema(schema.__data_schema_fields())
  end

  def to_runtime_schema([_ | _] = fields) do
    Enum.reduce(fields, [], fn
      {:has_one, {key, path, child_module}}, acc ->
        child_schema = to_runtime_schema(child_module)
        [{:has_one, {key, path, {child_module, child_schema}}} | acc]

      {:has_one, {key, path, child_module, opts}}, acc ->
        child_schema = to_runtime_schema(child_module)
        [{:has_one, {key, path, {child_module, child_schema}, opts}} | acc]

      {:has_many, {key, path, child_module}}, acc ->
        child_schema = to_runtime_schema(child_module)
        [{:has_many, {key, path, {child_module, child_schema}}} | acc]

      {:has_many, {key, path, child_module, opts}}, acc ->
        child_schema = to_runtime_schema(child_module)
        [{:has_many, {key, path, {child_module, child_schema}, opts}} | acc]

      # The aggregate schema already is runtime, but it may include "has_one"s etc inside it.
      {:aggregate, {key, nested_fields, cast_fn}}, acc ->
        nested_fields = to_runtime_schema(nested_fields)
        [{:aggregate, {key, nested_fields, cast_fn}} | acc]

      {:aggregate, {key, nested_fields, cast_fn, opts}}, acc ->
        nested_fields = to_runtime_schema(nested_fields)
        [{:aggregate, {key, nested_fields, cast_fn, opts}} | acc]

      field, acc ->
        [field | acc]
    end)
    |> :lists.reverse()
  end

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

                        {type, {_, _, {module, _}, _opts}}, _acc
                        when type in [:has_one, :has_many] and not is_atom(module) and
                               not is_map(module) ->
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
                                #{type}: {:foo, "path", {%{}, @foo_fields}}
                              ])

                          Or for an inline struct:

                              @foo_fields [
                                field: {:bar, "bar", &{:ok, to_string(&1)}}
                              ]

                              data_schema([
                                #{type}: {:foo, "path", {SomeStructModule, @foo_fields}}
                              ])


                          You provided the following as a schema: #{inspect(module)}.
                          Ensure you haven't used the wrong field type.
                          """

                          raise DataSchema.InvalidSchemaError, message: message

                        # the tuple case is handed above so we need to make sure we _dont
                        # error if the module is a tuple. So a tuple is allowed
                        {type, {_, _, module, _opts}}, _acc
                        when type in [:has_one, :has_many] and not is_atom(module) and
                               not is_tuple(module) ->
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
                                #{type}: {:foo, "path", {%{}, @foo_fields}}
                              ])

                          Or for an inline struct:

                              @foo_fields [
                                field: {:bar, "bar", &{:ok, to_string(&1)}}
                              ]

                              data_schema([
                                #{type}: {:foo, "path", {SomeStructModule, @foo_fields}}
                              ])


                          You provided the following as a schema: #{inspect(module)}.
                          Ensure you haven't used the wrong field type.
                          """

                          raise DataSchema.InvalidSchemaError, message: message

                        {type, {_, _, {module, _inline}}}, _acc
                        when type in [:has_one, :has_many] and not is_atom(module) and
                               not is_map(module) ->
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
                                #{type}: {:foo, "path", {%{}, @foo_fields}}
                              ])

                          Or for an inline struct:

                              @foo_fields [
                                field: {:bar, "bar", &{:ok, to_string(&1)}}
                              ]

                              data_schema([
                                #{type}: {:foo, "path", {SomeStructModule, @foo_fields}}
                              ])


                          You provided the following as a schema: #{inspect(module)}.
                          Ensure you haven't used the wrong field type.
                          """

                          raise DataSchema.InvalidSchemaError, message: message

                        # the tuple case is handed above so we need to make sure we _dont
                        # error if the module is a tuple. So a tuple is allowed
                        {type, {_, _, module}}, _acc
                        when type in [:has_one, :has_many] and not is_atom(module) and
                               not is_tuple(module) ->
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
                                #{type}: {:foo, "path", {%{}, @foo_fields}}
                              ])

                          Or for an inline struct:

                              @foo_fields [
                                field: {:bar, "bar", &{:ok, to_string(&1)}}
                              ]

                              data_schema([
                                #{type}: {:foo, "path", {SomeStructModule, @foo_fields}}
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
    if Code.ensure_loaded?(schema) && !function_exported?(schema, :__data_schema_fields, 0) do
      raise "Provided schema is not a valid DataSchema: #{inspect(schema)}"
    end

    fields = schema.__data_schema_fields()
    accessor = schema.__data_accessor()
    struct = struct(schema, %{})
    to_struct(data, struct, fields, accessor, opts)
  end

  def to_struct(data, struct, fields, accessor) do
    to_struct(data, struct, fields, accessor, [])
  end

  @doc """
  Creates a struct or map from the provided arguments. This function can be used to define
  runtime schemas for the most dynamic of cases. This means you don't have to define a schema
  at compile time using the `DataShema.data_schema/1` macro.

  ### Examples

  Creating a struct:

      defmodule Run do
        defstruct [:time]
      end

      input = %{"time" => "10:00"}
      fields = [
        field: {:time, "time", &{:ok, to_string(&1)}}
      ]
      DataSchema.to_struct(input, Run, fields, DataSchema.MapAccessor)
      {:ok, %Run{time: "10:00"}}

  Creating a map:

      input = %{"time" => "10:00"}
      fields = [
        field: {:time, "time", &{:ok, to_string(&1)}}
      ]
      DataSchema.to_struct(input, %{}, fields, DataSchema.MapAccessor)
      {:ok, %{time: "10:00"}}
  """
  # If we are passed a Module we assume it's a struct and create an empty one to reduce over.
  def to_struct(data, struct, fields, accessor, opts) when is_atom(struct) do
    to_struct(data, struct(struct, %{}), fields, accessor, opts)
  end

  def to_struct(data, %{} = struct, fields, accessor, opts) when is_list(fields) do
    # Right now we fail as soon as we get an error. If this error is nested deep then we
    # generate a recursive error that points to the value that caused it. We can imagine
    # instead "collecting" errors - meaning continuing with struct creation to gather up
    # all possible errors that will happen on struct creation. How to do this boggles the
    # mind a bit. But we'd need an option I do know that....
    # if we collect errors we'd need to define a traverse_errors fn that could collect all
    # the errors.
    # collect_errors? = Keyword.get(opts, :collect_errors, false)

    fields
    |> Enum.map(fn field ->
      defaults = %{
        optional?: false,
        empty_values: [nil]
      }

      case field do
        {type, {field, schema_mod, cast_fn}} ->
          {type, {field, schema_mod, cast_fn, defaults}}

        {type, {field, schema_mod, cast_fn, opts}} ->
          opts_as_map = Map.merge(defaults, Enum.into(opts, %{}))

          {type, {field, schema_mod, cast_fn, opts_as_map}}
      end
    end)
    |> Enum.reduce_while(struct, fn
      {:aggregate, {field, schema_mod, cast_fn, field_opts}}, struct when is_atom(schema_mod) ->
        fields = schema_mod.__data_schema_fields()
        accessor = schema_mod.__data_accessor()
        aggregate = struct(schema_mod, %{})

        aggregate(
          fields,
          accessor,
          data,
          opts,
          field,
          cast_fn,
          aggregate,
          struct,
          field_opts.optional?
        )

      {:aggregate, {field, fields, cast_fn, field_opts}}, struct when is_list(fields) ->
        aggregate(fields, accessor, data, opts, field, cast_fn, %{}, struct, field_opts.optional?)

      {field_type, {field, paths, cast_fn, field_opts}}, struct ->
        process_field({field_type, {field, paths, cast_fn, field_opts}}, struct, accessor, data)
    end)
    |> case do
      {:error, error_message} -> {:error, error_message}
      struct_or_map -> {:ok, struct_or_map}
    end
  end

  defp process_field(
         {:field, {field, path, cast_fn, %{optional?: nullable?}}},
         struct,
         accessor,
         data
       ) do
    case {accessor.field(data, path), nullable?} do
      {nil, false} ->
        {:halt, {:error, DataSchema.Errors.null_error(field)}}

      {value, _} ->
        case call_cast_fn(cast_fn, value) do
          {:ok, nil} ->
            if nullable? do
              {:cont, update_struct(struct, field, nil)}
            else
              # Instead of halt we would have to
              {:halt, {:error, DataSchema.Errors.null_error(field)}}
            end

          {:ok, value} ->
            {:cont, update_struct(struct, field, value)}

          {:error, message} ->
            {:halt, {:error, DataSchema.Errors.new({field, message})}}

          :error ->
            {:halt, {:error, DataSchema.Errors.default_error(field)}}

          other_value ->
            raise_incorrect_cast_function_error(field, other_value)
        end
    end
  end

  defp process_field(
         {:has_one, {field, path, {cast_module, inline_fields}, %{optional?: nullable?}}},
         struct,
         accessor,
         data
       ) do
    case accessor.has_one(data, path) do
      nil ->
        if nullable? do
          {:cont, update_struct(struct, field, nil)}
        else
          {:halt, {:error, DataSchema.Errors.null_error(field)}}
        end

      value ->
        case to_struct(value, cast_module, inline_fields, accessor, []) do
          # It's not possible for to_struct to return nil so we don't handle that case here
          {:ok, value} -> {:cont, update_struct(struct, field, value)}
          {:error, error} -> {:halt, {:error, DataSchema.Errors.new({field, error})}}
          :error -> {:halt, {:error, DataSchema.Errors.default_error(field)}}
        end
    end
  end

  defp process_field(
         {:has_one, {field, path, cast_module, %{optional?: nullable?}}},
         struct,
         accessor,
         data
       ) do
    case accessor.has_one(data, path) do
      nil ->
        if nullable? do
          {:cont, update_struct(struct, field, nil)}
        else
          {:halt, {:error, DataSchema.Errors.null_error(field)}}
        end

      value ->
        case to_struct(value, cast_module) do
          # It's not possible for to_struct to return nil so we don't handle that case here
          {:ok, value} -> {:cont, update_struct(struct, field, value)}
          {:error, error} -> {:halt, {:error, DataSchema.Errors.new({field, error})}}
          :error -> {:halt, {:error, DataSchema.Errors.default_error(field)}}
        end
    end
  end

  defp process_field(
         {:has_many, {field, path, {cast_module, inline_fields}, %{optional?: nullable?}}},
         struct,
         accessor,
         data
       ) do
    case accessor.has_many(data, path) do
      nil ->
        if nullable? do
          {:cont, update_struct(struct, field, nil)}
        else
          {:halt, {:error, DataSchema.Errors.null_error(field)}}
        end

      data ->
        data
        |> Enum.reduce_while([], fn datum, acc ->
          # It's not possible for to_struct to return nil so we don't worry about it here.
          # Should we use the parent data accessor or should we require that the struct
          # defines one?
          # using the parent always doesn't work for compile time schemas. So that's hout
          # now doing one thing for both is either confusing or complicated.
          case to_struct(datum, cast_module, inline_fields, accessor, []) do
            {:ok, struct} -> {:cont, [struct | acc]}
            {:error, error} -> {:halt, {:error, DataSchema.Errors.new({field, error})}}
            :error -> {:halt, {:error, DataSchema.Errors.default_error(field)}}
          end
        end)
        |> case do
          {:error, _} = error ->
            {:halt, error}

          relations when is_list(relations) ->
            {:cont, update_struct(struct, field, :lists.reverse(relations))}
        end
    end
  end

  defp process_field(
         {:has_many, {field, path, cast_module, %{optional?: nullable?}}},
         struct,
         accessor,
         data
       ) do
    case accessor.has_many(data, path) do
      nil ->
        if nullable? do
          {:cont, update_struct(struct, field, nil)}
        else
          {:halt, {:error, DataSchema.Errors.null_error(field)}}
        end

      data ->
        data
        |> Enum.reduce_while([], fn datum, acc ->
          # It's not possible for to_struct to return nil so we don't worry about it here.
          case to_struct(datum, cast_module) do
            {:ok, struct} -> {:cont, [struct | acc]}
            {:error, error} -> {:halt, {:error, DataSchema.Errors.new({field, error})}}
            :error -> {:halt, {:error, DataSchema.Errors.default_error(field)}}
          end
        end)
        |> case do
          {:error, %DataSchema.Errors{}} = error ->
            {:halt, error}

          relations when is_list(relations) ->
            {:cont, update_struct(struct, field, :lists.reverse(relations))}
        end
    end
  end

  defp process_field(
         {:list_of, {field, path, cast_module, %{optional?: nullable?}}},
         struct,
         accessor,
         data
       ) do
    case accessor.list_of(data, path) do
      nil ->
        if nullable? do
          {:cont, update_struct(struct, field, nil)}
        else
          {:halt, {:error, DataSchema.Errors.null_error(field)}}
        end

      data ->
        data
        |> Enum.reduce_while([], fn datum, acc ->
          case call_cast_fn(cast_module, datum) do
            {:ok, nil} ->
              if nullable? do
                # Do we add nil or do we remove them? a list of nils seeeeems bad. But is it
                # better to not remove information...?
                {:cont, [nil | acc]}
              else
                {:halt, {:error, DataSchema.Errors.null_error(field)}}
              end

            {:ok, value} ->
              {:cont, [value | acc]}

            {:error, error} ->
              {:halt, {:error, DataSchema.Errors.new({field, error})}}

            :error ->
              {:halt, {:error, DataSchema.Errors.default_error(field)}}

            other_value ->
              raise_incorrect_cast_function_error(field, other_value)
          end
        end)
        |> case do
          {:error, %DataSchema.Errors{}} = error ->
            {:halt, error}

          relations when is_list(relations) ->
            {:cont, update_struct(struct, field, :lists.reverse(relations))}
        end
    end
  end

  defp aggregate(fields, accessor, data, opts, field, cast_fn, aggregate, parent, nullable?) do
    case to_struct(data, aggregate, fields, accessor, opts) do
      {:error, %DataSchema.Errors{} = error} ->
        {:halt, {:error, DataSchema.Errors.new({field, error})}}

      {:ok, values_map} ->
        case call_cast_fn(cast_fn, values_map) do
          {:ok, nil} ->
            if nullable? do
              {:cont, update_struct(parent, field, nil)}
            else
              {:halt, {:error, DataSchema.Errors.null_error(field)}}
            end

          {:ok, value} ->
            {:cont, update_struct(parent, field, value)}

          {:error, error} ->
            {:halt, {:error, DataSchema.Errors.new({field, error})}}

          :error ->
            {:halt, {:error, DataSchema.Errors.default_error(field)}}

          other_value ->
            raise_incorrect_cast_function_error(field, other_value)
        end
    end
  end

  defp raise_incorrect_cast_function_error(field, value) do
    message = """
    Casting error for field #{field}, cast function should return one of the following:

      {:ok, any()} | :error | {:error, any()}

    Cast function returned #{inspect(value)}
    """

    raise DataSchema.InvalidCastFunction, message: message
  end

  # Sometimes the data we are creating is a map, sometimes a struct. When it is a struct
  # we want to know the field exists before we add it.
  defp update_struct(%_struct_name{} = struct, field, item) do
    %{struct | field => item}
  end

  defp update_struct(%{} = map, field, item) do
    Map.put(map, field, item)
  end

  # This just lets us use either a module name for the data type OR a one arity fn.
  defp call_cast_fn({module, fun, args}, value), do: apply(module, fun, [value | args])
  defp call_cast_fn(module, value) when is_atom(module), do: module.cast(value)
  defp call_cast_fn(fun, value) when is_function(fun, 1), do: fun.(value)

  @doc """
       A private function that aims to return a flat list of all of the absolute paths
       in a given schema. This only works if the path is a list though, as would be the case
       if you had an Access data accessor for example. This is useful groundwork for the same
       idea with other paths though - you would just have to modify it slightly I think to get
       what you want.
       """ && false
  def absolute_paths_for_schema(schema) when is_atom(schema) do
    if Code.ensure_loaded?(schema) &&
         !function_exported?(schema, :__data_schema_fields, 0) do
      raise "Provided schema is not a valid DataSchema: #{inspect(schema)}"
    end

    schema
    |> to_runtime_schema()
    |> absolute_paths_for_schema()
  end

  def absolute_paths_for_schema(runtime_schema) when is_list(runtime_schema) do
    absolute_paths_for_schema(runtime_schema, [])
  end

  def absolute_paths_for_schema(runtime_schema, acc) when is_list(runtime_schema) do
    runtime_schema
    |> Enum.reduce(acc, fn
      {:has_many, {_key, path, {_child_schema, child_fields}, _opts}}, acc ->
        child_fields
        |> absolute_paths_for_schema([])
        |> Enum.reduce(acc, fn
          {p, modifier}, accu ->
            [{path ++ p, modifier} | accu]
        end)

      {:has_many, {_key, path, {_child_schema, child_fields}}}, acc ->
        child_fields
        |> absolute_paths_for_schema([])
        |> Enum.reduce(acc, fn
          {p, modifier}, accu ->
            [{path ++ p, modifier} | accu]
        end)

      {:has_one, {_key, path, {_child_schema, child_fields}, _opts}}, acc ->
        child_fields
        |> absolute_paths_for_schema([])
        |> Enum.reduce(acc, fn
          {p, modifier}, accu ->
            [{path ++ p, modifier} | accu]
        end)

      {:has_one, {_key, path, {_child_schema, child_fields}}}, acc ->
        child_fields
        |> absolute_paths_for_schema([])
        |> Enum.reduce(acc, fn
          {p, modifier}, accu ->
            [{path ++ p, modifier} | accu]
        end)

      {:aggregate, {_key, child_fields, _cast_fn}}, acc ->
        absolute_paths_for_schema(child_fields, acc)

      {:aggregate, {_key, child_fields, _cast_fn, _opts}}, acc ->
        absolute_paths_for_schema(child_fields, acc)

      {_field, {_key, path, _cast_fn}}, acc ->
        [path | acc]

      {_field, {_key, path, _cast_fn, _opts}}, acc ->
        [path | acc]
    end)
  end
end
