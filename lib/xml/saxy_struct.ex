defmodule DataSchema.XML.SaxyStruct do
  @moduledoc """
  Experiments in efficient XML parsing. This is a Saxy handler that only keeps elements
  that appear in a data schema. It builds a simple form representation of the XML, but
  only puts in elements and attributes that exist in a schema. Check the tests for examples
  of what the schema should look like (it should be a tree that mirrors the structure).
  """

  @behaviour Saxy.Handler

  @impl true
  def handle_event(:start_document, _prolog, state) do
    {:ok, state}
  end

  # If there is a duplicate tag name inside a tag we are skipping we need to be sure we
  # don't stop skipping when that duplicate tag closes. We have opted to keep a count of
  # how many times we have opened this tag we are skipping, and we stop skipping when we
  # we close the skipped element and the count is 0.
  # An alternative would be to add a {:skipped  tuple for every nested duplicate tag but I
  # think this would be a larger memory footprint as a tuple > an int.
  def handle_event(:start_element, {tag_name, _}, {schemas, [{:skip, count, tag_name} | stack], seen}) do
    {:ok, {schemas, [{:skip, count + 1, tag_name} | stack], seen}}
  end

  def handle_event(:start_element, _element, {_, [{:skip, _, _} | _], _seen} = state) do
    {:ok, state}
  end

  def handle_event(:start_element, {tag_name, attributes}, {schemas, stack, seen}) do
    [current_schema | rest_schemas] = schemas

    case Map.pop(unwrap_schema(current_schema), tag_name, :not_found) do
      {:not_found, _} ->
        case seen do
          [{^tag_name, current_seen} | _rest_seen] ->
            {:stop, {:error, "Saw many expected one!"}}

          _ ->
            {:ok, {schemas, [{:skip, 0, tag_name} | stack], seen}}
        end

      {{acc, {:all, child_schema}}, sibling_schema} ->
        case stack do
          # This case is when we see a repeated tag. It means we do less work because
          # we know we don't have to touch the schemas here at all.
          [{^tag_name, _, _} | _] ->
            case get_attributes(attributes, child_schema, acc) do
              {:error, _} = error ->
                {:stop, error}

              attributes ->
                tag = {tag_name, attributes, []}
                {:ok, {schemas, [tag | stack], seen}}
            end

          [{_parent_tag, _, _} | _] ->
            case get_attributes(attributes, child_schema, acc) do
              {:error, _} = error ->
                {:stop, error}

              attributes ->
                tag = {tag_name, attributes, []}

                schemas = [
                  {:all, child_schema},
                  Map.put(sibling_schema, tag_name, {:all, child_schema}) | rest_schemas
                ]

                {:ok, {schemas, [tag | stack], seen}}
            end
        end

      {{parent_key, :has_one, {child_acc, child_schema}, opts}, sibling_schema} ->
        case get_attributes(attributes, child_schema, child_acc) do
          {:error, _} = error ->
            {:stop, error}

          with_attributes ->
            schemas = [child_schema, sibling_schema | rest_schemas]
            {:ok, {schemas, [{tag_name, parent_key, :has_one, with_attributes, opts} | stack], seen}}
        end

      {{acc, child_schema}, sibling_schema} ->
        case get_attributes(attributes, child_schema, acc) do
          {:error, _} = error ->
            {:stop, error}

          with_attributes ->
            schemas = [child_schema, sibling_schema | rest_schemas]
            [_ | rest_stack] = stack
            {:ok, {schemas, [with_attributes | rest_stack], seen}}
        end

      {child_schema, sibling_schema} ->
        # We may have to case the acc here as it could be a has_one?
        [acc | rest_stack] = stack

        case get_attributes(attributes, child_schema, acc) do
          {:error, _} = error ->
            {:stop, error}

          with_attributes ->
                seen =
          case seen do
            [] ->
              [{tag_name, %{}}]

            [{parent_tag, current_seen} | rest_seen] ->
              [{tag_name, %{}}, {parent_tag, Map.put(current_seen, tag_name, true)} | rest_seen]
          end


            schemas = [child_schema, sibling_schema | rest_schemas]
            {:ok, {schemas, [with_attributes | rest_stack], seen}}
        end
    end
  end

  def handle_event(:characters, _element, {_, [{:skip, _, _} | _]} = state) do
    {:ok, state}
  end

  def handle_event(:characters, chars, {schemas, stack, seen} = state) do
    [current_schema | _rest_schemas] = schemas

    case Map.get(unwrap_schema(current_schema), :text, :not_found) do
      :not_found ->
        {:ok, state}

      {key, :field, cast_fn, opts} ->
        case cast_value({key, cast_fn, opts}, chars) do
          {:ok, value} ->
            case stack do
              [{parent_tag, parent_key, :has_one, child_acc, opts} | rest_stack] ->
                updated_child = update_accumulator(child_acc, key, value)
                updated = {parent_tag, parent_key, :has_one, updated_child, opts}
                {:ok, {schemas, [updated | rest_stack], seen}}

              [acc | rest_stack] ->
                {:ok, {schemas, [update_accumulator(acc, key, value) | rest_stack], seen}}
            end

          {:error, _} = error ->
            {:stop, error}
        end
    end
  end

  def handle_event(:cdata, chars, {schemas, stack, seen}) do
    [{tag_name, attributes, content} | stack] = stack
    # We probably want to like parse the cdata... But leave like this for now.
    # We also want to only add it if it's in the schema, but until we have a c-data example
    # let's just always include it and see how we need to handle it later?
    current = {tag_name, attributes, [{:cdata, chars} | content]}
    {:ok, {schemas, [current | stack], seen}}
  end

  def handle_event(
        :end_element,
        element_name,
        {schemas, [{:skip, 0, element_name} | stack], seen}
      ) do
    # We need to remove ONLY when we are closing the parent of this tag.
    # how do we track parent. We have to put it into the stack somewhere.

    case seen do
      [] ->
        {:ok, {schemas, stack, seen}}

      [_ | rest_seen] ->
        {:ok, {schemas, stack, rest_seen}}
    end
  end

  def handle_event(:end_element, element_name, {schemas, [{:skip, count, element_name} | stack], seen}) do
    {:ok, {schemas, [{:skip, count - 1, element_name} | stack], seen}}
  end

  def handle_event(:end_element, _element_name, {_schemas, [{:skip, _, _} | _], _seen} = state) do
    {:ok, state}
  end

  def handle_event(
        :end_element,
        tag_name,
        {schemas, [{tag_name, parent_key, :has_one, child_acc, _opts}, acc | rest_stack], seen}
      ) do
    [_current_schema | rest_schemas] = schemas
    with_child = update_accumulator(acc, parent_key, child_acc)
    {:ok, {rest_schemas, [with_child | rest_stack], seen}}
  end

  def handle_event(:end_element, _tag_name, {schemas, stack, seen}) do
    [_current_schema | rest_schemas] = schemas

    case stack do
      [parent | rest] ->
        {:ok, {rest_schemas, [parent | rest], seen}}
    end
  end

  def handle_event(:end_document, _, state) do
    {:ok, state}
  end

  defp unwrap_schema({:all, schema}), do: schema
  defp unwrap_schema(%{} = schema), do: schema

  def parse_string(data, schema) do
    state = {[schema], [%{}], []}

    case Saxy.parse_string(data, __MODULE__, state, []) do
      {:ok, {:error, _reason} = error} -> error
      # If we are returned an empty stack that means nothing in the XML was in the schema.
      # If we found even one thing we would be returned a simple form node.
      {:ok, {_, [], _}} -> {:error, :not_found}
      {:ok, {_, [struct], _}} -> {:ok, struct}
    end
  end

  defp get_attributes(attributes, schema, acc) do
    Enum.reduce_while(attributes, acc, fn {attr, value}, acc ->
      case Map.get(schema, {:attr, attr}, :not_found) do
        :not_found ->
          {:cont, acc}

        {key, :field, cast_fn, opts} ->
          case cast_value({key, cast_fn, opts}, value) do
            {:ok, value} -> {:cont, update_accumulator(acc, key, value)}
            {:error, _} = error -> {:halt, error}
          end
      end
    end)
  end

  defp cast_value({key, cast_fn, opts}, value) do
    nullable? = Keyword.get(opts, :optional?, false)

    case {call_cast_fn(cast_fn, value), nullable?} do
      {{:ok, nil}, true} ->
        {:ok, nil}

      {{:ok, nil}, false} ->
        {:error, DataSchema.Errors.null_error(key)}

      {{:ok, value}, _nullable?} ->
        {:ok, value}

      {{:error, message}, _nullable?} ->
        {:error, DataSchema.Errors.new({key, message})}

      {:error, nullable} when nullable in [true, false] ->
        {:error, DataSchema.Errors.default_error(key)}

      {value, nullable} when nullable in [true, false] ->
        # We should add the module to the error message here when we add the struct
        message = """
        Casting error for field #{key}, cast function should return one of the following:

          {:ok, any()} | :error | {:error, any()}

        Cast function returned #{inspect(value)}
        """

        raise DataSchema.InvalidCastFunction, message: message
    end
  end

  defp update_accumulator({parent_tag, parent_key, :has_one, acc, opts}, key, value) do
    updated = update_accumulator(acc, key, value)
    {parent_tag, parent_key, :has_one, updated, opts}
  end

  defp update_accumulator(%_struct{} = acc, key, value), do: %{acc | key => value}
  defp update_accumulator(%{} = acc, key, value), do: Map.put(acc, key, value)

  defp call_cast_fn({module, fun, args}, value), do: apply(module, fun, [value | args])
  defp call_cast_fn(module, value) when is_atom(module), do: module.cast(value)
  defp call_cast_fn(fun, value) when is_function(fun, 1), do: fun.(value)
end
