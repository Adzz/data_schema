defmodule Duffel.Link.XMLSchema do
  @moduledoc false
  @doc """
  Use this (geddit) to create an xml schema:

  ### Example

      defmodule Thing do
        use LivebookContext.XmlSchema
        data_schema([
          field: {:wot, "/Wat/text()", &{:ok, &1}}
        ])
      end
  """
  defmacro __using__(_) do
    quote do
      import DataSchema, only: [data_schema: 1]
      @data_accessor Duffel.Link.XpathAccessor
    end
  end

  defmacro xml_schema(fields) do
    quote do
      import DataSchema, only: [data_schema: 1]

      Duffel.Link.XMLSchema.validate_fields!(unquote(fields), __MODULE__)
      @data_accessor Duffel.Link.SimpleForm.DataAccess
      data_schema(unquote(fields))
    end
  end

  @doc """
  Validates the schema fields of a data schema. We call this at compile time to help give
  useful error messages for any xml data schemas. These errors should help guide the
  implementer towards a correct paths in the schemas.
  """
  # credo:disable-for-lines:300 Credo.Check.Refactor.CyclomaticComplexity
  # credo:disable-for-lines:300 Credo.Check.Refactor.Nesting
  def validate_fields!(fields, module) do
    Enum.each(fields, fn
      {field, {key, {_path, _modifier} = full_path, _cast_fn, _opts}}
      when field in [:has_one, :has_many] ->
        invalid_modifier_error(field, key, full_path, module)

      {field, {key, {_path, _modifier} = full_path, _opts}}
      when field in [:has_one, :has_many] ->
        invalid_modifier_error(field, key, full_path, module)

      {:has_many, {key, path, _, _}} ->
        if not Enum.any?(path, &match?({:all, _}, &1)) do
          missing_all_path_error(:has_many, key, path, module)
        end

      {:has_many, {key, path, _}} ->
        if not Enum.any?(path, &match?({:all, _}, &1)) do
          missing_all_path_error(:has_many, key, path, module)
        end

      {:has_one, {key, path, _cast_fn, _opts}} ->
        if Enum.any?(path, &match?({:all, _}, &1)) do
          all_modifier_error(:has_one, key, path, module)
        end

      {:has_one, {key, path, _opts}} ->
        if Enum.any?(path, &match?({:all, _}, &1)) do
          all_modifier_error(:has_one, key, path, module)
        end

      {:list_of, {key, {path, modifier} = full_path, _cast_fn}} ->
        if not Enum.any?(path, &match?({:all, _}, &1)) do
          missing_all_path_error(:list_of, key, full_path, module)
        end

        validate_modifier!(modifier, key, module, full_path)

      {:list_of, {key, {path, modifier} = full_path, _cast_fn, _opts}} ->
        if not Enum.any?(path, &match?({:all, _}, &1)) do
          missing_all_path_error(:list_of, key, full_path, module)
        end

        validate_modifier!(modifier, key, module, full_path)

      {:list_of, {key, path, _cast_fn}} ->
        if not Enum.any?(path, &match?({:all, _}, &1)) do
          missing_all_path_error(:list_of, key, path, module)
        end

      {:list_of, {key, path, _cast_fn, _opts}} ->
        if not Enum.any?(path, &match?({:all, _}, &1)) do
          missing_all_path_error(:list_of, key, path, module)
        end

      {:field, {key, path, _cast_fn, _opts}} ->
        case path do
          {[_ | _] = path, :text} ->
            if Enum.any?(path, &match?({:all, _}, &1)) do
              all_modifier_error(:field, key, path, module)
            end

          {[_ | _] = path, {:attr, _}} ->
            if Enum.any?(path, &match?({:all, _}, &1)) do
              all_modifier_error(:field, key, path, module)
            end

          path ->
            field_path_error(key, path, module)
        end

      {:field, {key, path, _cast_fn}} ->
        case path do
          {[_ | _] = path, :text} ->
            if Enum.any?(path, &match?({:all, _}, &1)) do
              all_modifier_error(:field, key, path, module)
            end

          {[_ | _] = path, {:attr, _}} ->
            if Enum.any?(path, &match?({:all, _}, &1)) do
              all_modifier_error(:field, key, path, module)
            end

          path ->
            field_path_error(key, path, module)
        end

      {:aggregate, {key, paths, _cast_fn}} ->
        if not is_list(paths) do
          invalid_aggregate_fields_error(key, paths, module)
        end

        validate_fields!(paths, module)

      {:aggregate, {key, paths, _cast_fn, _opts}} ->
        if not is_list(paths) do
          invalid_aggregate_fields_error(key, paths, module)
        end

        validate_fields!(paths, module)

      _field ->
        nil
    end)
  end

  defp validate_modifier!(:text, _, _, _), do: :ok
  defp validate_modifier!({:attr, _}, _, _, _), do: :ok

  defp validate_modifier!(_modifier, key, module, path) do
    raise Duffel.Link.SimpleForm.DataAccess.PathError, """


        Invalid path for #{inspect(key)} in #{inspect(module)}

        Path modifiers can only be `:text` or `{:attr, attr_name}`

        Path was: #{inspect(path)}

    """
  end

  defp invalid_aggregate_fields_error(key, path, module) do
    raise Duffel.Link.SimpleForm.DataAccess.PathError, """


        Invalid path for #{inspect(key)} in #{inspect(module)}

        An :aggregate's path should be an inline schema, for example:

            @aggregate_path [
              field: {:first_name, ["FirstName"], StringType},
              field: {:last_name, ["LastName"], StringType},
            ]
            xml_schema(
              aggregate: {
                :name,
                @aggregate_path,
                fn %{first_name: first, last_name: last} ->
                  {:ok, first_name <> " " <> last_name}
                end
              }
            )

        Check the data schema docs if you are unsure.

        Path was: #{inspect(path)}

    """
  end

  defp field_path_error(key, path, module) do
    raise Duffel.Link.SimpleForm.DataAccess.PathError, """


        Invalid path for #{inspect(key)} in #{inspect(module)}

        A :field should point to the text or an attribute of an XML node only

        A schema field should look something like this:

            field: {:my_key, {["A", "B"], :text}, StringType}

        OR

            field: {:my_key, {["A", "B"], {:attr, "myAttr}}, StringType}

        Path was: #{inspect(path)}

    """
  end

  defp all_modifier_error(field, key, path, module) do
    raise Duffel.Link.SimpleForm.DataAccess.PathError, """


        Invalid path for #{inspect(key)} in #{inspect(module)}

        #{field} should point to a single XML node but the path
        includes {:all, _} element.

        Path was: #{inspect(path)}
    """
  end

  defp invalid_modifier_error(field, key, full_path, module) do
    raise Duffel.Link.SimpleForm.DataAccess.PathError, """


        Invalid path for #{inspect(key)} in #{inspect(module)}

        #{field} cannot contain :text or {:attr, _} modifiers, they should
        always return paths to nested XML nodes. If you have included a
        modifier check your path and remove it.

        Path was: #{inspect(full_path)}
    """
  end

  defp missing_all_path_error(field, key, path, module) do
    raise Duffel.Link.SimpleForm.DataAccess.PathError, """


        Invalid path for #{inspect(key)} in #{inspect(module)}

        #{field} fields should target multiple tags. You likely
        stopped one node too early or forgot the {:all, _} modifier.

        For example if your xml looks like this:

            <A>
              <B />
              <B />
            </A>

        and you want all Bs your schema should be:

            #{field}: {:b, ["A", {:all, "B"}], YourModule}

        Path path was: #{inspect(path)}

    """
  end
end
