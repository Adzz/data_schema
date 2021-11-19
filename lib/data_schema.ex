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

  # @doc """
  # Accepts an data schema module and some source data and attempts to create the struct
  # defined in the schema from the source data recursively.

  # We essentially visit each field in the schema and extract the data the field points to
  # from the sauce data, passing it to the field's casting function before setting the
  # result of that as the value on the struct.

  # This function takes a simple approach to creating the struct - whatever you return from
  # a casting function will be set as the value of the struct field. You should raise if
  # you want casting to fail.

  # ### Examples

  #     data = %{ "spice" => "enables space travel" }

  #     defmodule Foo do
  #       require DataSchema

  #       DataSchema.data_schema(
  #         field: {:a_rocket, "spice", &({:ok, &1})}
  #       )
  #     end

  #     DataSchema.to_struct(data, Foo)
  #     # => Outputs the following:
  #     %Foo{a_rocket: "enables space travel"}
  # """

  # Note we should make a to_struct() that lets the accessor return a tuple and we can
  # reduce_while, bail out with an error in the case of failure,

  @doc """
  """
  def to_struct(data, %schema{}) do
    to_struct(data, schema)
  end

  # There are two ways to do this we could let accessors return ok tuples and that would
  # allow for bailing out if they error for some reason. Which would be an easy way to
  # implement something like "This has to be in the source data" without raising.
  # BUT that is hard to explain. In practice it's probably easier to handle that in casting
  # and have the cast fns PM on nil. That would mean

  # Also when casting we could have a :error / :ok convention so that we can bail out if
  # casting fails with an error (o course then you gets ta thinking that we should collect
  # errors then you have changesets). But yea do we need both.........??

  # The question is also "how do we enforce not null" there is both "you can't create the
  # struct with nil value" and there is the "you can never set it to nil". We can enforce
  # the latter if someone always uses this to_struct to create the thing.
  def to_struct(data, schema) do
    accessor = schema.__data_accessor()

    Enum.reduce_while(schema.__data_schema_fields(), struct(schema, %{}), fn
      {:aggregate, {field, %{} = paths, cast_fn, _opts}}, struct ->
        values_map =
          Map.new(paths, fn {key, path} ->
            {key, accessor.aggregate(data, path)}
          end)

        case call_cast_fn(cast_fn, values_map) do
          {:ok, value} -> {:cont, %{struct | field => value}}
          {:error, _} = error -> {:halt, error}
          :error -> {:halt, :error}
        end

      {:aggregate, {field, %{} = paths, cast_fn}}, struct ->
        values_map =
          Map.new(paths, fn {key, path} ->
            {key, accessor.aggregate(data, path)}
          end)

        case call_cast_fn(cast_fn, values_map) do
          {:ok, value} -> {:cont, %{struct | field => value}}
          {:error, _} = error -> {:halt, error}
          :error -> {:halt, :error}
        end

      {:field, {field, path, cast_fn, _opts}}, struct ->
        case call_cast_fn(cast_fn, accessor.field(data, path)) do
          {:ok, value} -> {:cont, %{struct | field => value}}
          {:error, _} = error -> {:halt, error}
          :error -> {:halt, :error}
        end

      # can we generalize? Is apply a perf thing>
      # {field_type, {struct_key, path, cast_fn}}, struct ->
      #   case call_cast_fn(cast_fn, apply(accessor, field_type, [data, path])) do
      #     {:ok, value} -> {:cont, %{struct | field => value}}
      #     {:error, _} = error -> {:halt, error}
      #     :error -> {:halt, :error}
      #   end

      {:field, {field, path, cast_fn}}, struct ->
        case call_cast_fn(cast_fn, accessor.field(data, path)) do
          {:ok, value} -> {:cont, %{struct | field => value}}
          {:error, _} = error -> {:halt, error}
          :error -> {:halt, :error}
        end

      {:has_one, {field, path, cast_module, _opts}}, struct ->
        case call_cast_fn(cast_module, accessor.has_one(data, path)) do
          {:error, _} = error -> {:halt, error}
          :error -> {:halt, :error}
          {:ok, value} -> {:cont, %{struct | field => value}}
        end

      {:has_one, {field, path, cast_module}}, struct ->
        case call_cast_fn(cast_module, accessor.has_one(data, path)) do
          {:error, _} = error -> {:halt, error}
          :error -> {:halt, :error}
          {:ok, value} -> {:cont, %{struct | field => value}}
        end

      # We could have access to :optional? here which allows for runtime validation that
      # it exists or not. But default it should be needed. Or we just let casting handle it
      # But given that we have optional as a thing we really need to continue to back it up here
      # If you use it on a list then like it's a thing
      {:list_of, {field, path, cast_module, _opts}}, struct ->
        accessor.list_of(data, path)
        |> Enum.reduce_while([], fn datum, acc ->
          case call_cast_fn(cast_module, datum) do
            {:ok, value} -> {:cont, [value | acc]}
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

      {:list_of, {field, path, cast_module}}, struct ->
        accessor.list_of(data, path)
        |> Enum.reduce_while([], fn datum, acc ->
          case call_cast_fn(cast_module, datum) do
            {:ok, value} -> {:cont, [value | acc]}
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
    end)
  end

  # This just lets us use either a module name for the data type OR a one arity fn.
  defp call_cast_fn(module, value) when is_atom(module), do: module.cast(value)
  defp call_cast_fn(fun, value) when is_function(fun, 1), do: fun.(value)
end
