defmodule DataSchema.CastFunctionError do
  @moduledoc """
  An error for when a casting function does not return the correct data.

  All casting functions get wrapped  in a `rescue` to catch any unexpected exceptions. This
  lets us add more useful information about where the error occurred that the stack trace
  cannot provide - mainly which field failed the casting.

  We then raise using the original stacktrace and printing the captured error message.

  ### Matching on Specific Exceptions

  If a user wishes to capture specific exceptions as part of casting they may do so by
  matching on the `:wrapped_error` field. For example:

      try do
        DataSchema.to_struct(my_input, MySchema)
      rescue
        %DataSchema.CastFunctionError{wrapped_error: %RuntimeError{}} ->
          Logger.error("Expected Runtime Error")
        error ->
          reraise error, __STACKTRACE__
      end
  """
  defexception [
    :message,
    :casted_value,
    :leaf_field,
    :path,
    :wrapped_error,
    :stacktrace_of_wrapped_error
  ]

  @doc """
  Creates an appropriate error message from the given struct.
  """
  def error_message(%__MODULE__{
        casted_value: value,
        path: path,
        leaf_field: leaf_field,
        wrapped_error: wrapped_error
      }) do
    """


    Unexpected error when casting value #{inspect(value)}
    #{field_message(path, leaf_field)}
    Full path to field was:

    #{inspect_path(path)}
    The casting function raised the following error:

    #{Exception.format(:error, wrapped_error)}
    """
  end

  defp field_message(path, leaf_field) do
    case List.last(path) do
      {schema, field} when is_atom(field) ->
        """
        for field #{inspect(field)} in schema #{inspect(schema)}
        """

      field when is_atom(field) ->
        """
        for field #{inspect(field)} in this part of the schema:

        #{formatted_field(leaf_field)}
        """
    end
  end

  defp inspect_path(path) do
    [first | rest] = path |> Enum.reverse()

    rest
    |> Enum.reduce("      #{node_to_string(first)}", fn field, acc ->
      acc <> "Under " <> node_to_string(field)
    end)
  end

  defp node_to_string({module, field}) do
    "Field  #{inspect(field)} in #{inspect(module)}\n"
  end

  defp node_to_string(field) do
    "Field  #{inspect(field)}\n"
  end

  # What happens with aggregate?
  defp formatted_field({:field, rest}) do
    "field: #{inspect(rest)},"
  end

  defp formatted_field({:has_one, rest}) do
    "has_one: #{inspect(rest)},"
  end

  defp formatted_field({:has_many, rest}) do
    "has_many: #{inspect(rest)},"
  end

  defp formatted_field({:list_of, rest}) do
    "list_of: #{inspect(rest)},"
  end

  defp formatted_field({:aggregate, {field, path, cast, opts}}) do
    """
    @aggregate_fields [
      #{Enum.map_join(path, "\n  ", &formatted_field/1)}
    ]
    aggregate: {#{inspect(field)}, @aggregate_fields, #{inspect(cast)}, #{inspect(opts)}},
    """
  end

  defp formatted_field({:aggregate, {field, path, cast}}) do
    """
    @aggregate_fields [
      #{Enum.map_join(path, "\n  ", &formatted_field/1)}
    ]
    aggregate: {#{inspect(field)}, @aggregate_fields, #{inspect(cast)}},
    """
  end
end
