defmodule DataSchema.XML.Saxy do
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

  # do we need to add "seen" to state? Seems wasteful! more memory surely.

  def handle_event(
        :start_element,
        {tag_name, _},
        {schemas, [{:skip, count, tag_name} | stack], seen}
      ) do
    # If we are seeing a node again then we must have already done the check the first time
    # so we don't need to check "seen" again.
    {:ok, {schemas, [{:skip, count + 1, tag_name} | stack], seen}}
  end

  def handle_event(:start_element, element, {_, [{:skip, _, _} | _], seen} = state) do
    {tage_nane, _} = element

    if Map.get(seen, tage_nane) do
      {:stop, {:error, "Saw many expected one!"}}
    else
      {:ok, state}
    end
  end

  # so we need a map of visited nodes, how do we ensure it's not _all_ nodes?
  # only needs to be the has_ones tbh - ie non `{:all}`

  def handle_event(:start_element, {tag_name, attributes}, {schemas, stack, seen}) do
    [current_schema | rest_schemas] = schemas

    case Map.pop(unwrap_schema(current_schema), tag_name, :not_found) do
      {:not_found, _} ->
        {:ok, {schemas, [{:skip, 0, tag_name} | stack], seen}}

      {{:all, child_schema}, sibling_schema} ->
        case stack do
          # This case is when we see a repeated tag. It means we do less work because
          # we know we don't have to touch the schemas here at all.
          [{^tag_name, _, _} | _] ->
            attributes =
              Enum.filter(attributes, fn {attr, _value} ->
                Map.get(child_schema, {:attr, attr}, false)
              end)

            tag = {tag_name, attributes, []}
            {:ok, {schemas, [tag | stack], seen}}

          [{_parent_tag, _, _} | _] ->
            attributes =
              Enum.filter(attributes, fn {attr, _value} ->
                Map.get(child_schema, {:attr, attr}, false)
              end)

            tag = {tag_name, attributes, []}

            schemas = [
              {:all, child_schema},
              Map.put(sibling_schema, tag_name, {:all, child_schema}) | rest_schemas
            ]

            {:ok, {schemas, [tag | stack], seen}}
        end

      {child_schema, sibling_schema} ->
        attributes =
          Enum.filter(attributes, fn {attr, _value} ->
            Map.get(child_schema, {:attr, attr}, false)
          end)

        # Do we put it in here? we only need siblings?
        tag = {tag_name, attributes, []}
        schemas = [child_schema, sibling_schema | rest_schemas]
        {:ok, {schemas, [tag | stack], Map.put(seen, tag_name, true)}}
    end
  end

  def handle_event(:characters, _element, {_, [{:skip, _, _} | _], _seen} = state) do
    {:ok, state}
  end

  def handle_event(:characters, chars, {schemas, stack, seen} = state) do
    [current_schema | _rest_schemas] = schemas

    case Map.get(unwrap_schema(current_schema), :text, :not_found) do
      :not_found ->
        {:ok, state}

      true ->
        [{tag_name, attributes, content} | stack] = stack
        current = {tag_name, attributes, [chars | content]}
        {:ok, {schemas, [current | stack], seen}}
    end
  end

  def handle_event(:cdata, chars, {schemas, stack, seen}) do
    [{tag_name, attributes, content} | stack] = stack
    # We probably want to like parse the cdata... But leave like this for now.
    # We also want to only add it if it's in the schema, but until we have a c-data example
    # let's just always include it and see how we need to handle it later.
    current = {tag_name, attributes, [{:cdata, chars} | content]}
    {:ok, {schemas, [current | stack], seen}}
  end

  def handle_event(
        :end_element,
        element_name,
        {schemas, [{:skip, 0, element_name} | stack], seen}
      ) do
    {:ok, {schemas, stack, seen}}
  end

  def handle_event(
        :end_element,
        element_name,
        {schemas, [{:skip, count, element_name} | stack], seen}
      ) do
    {:ok, {schemas, [{:skip, count - 1, element_name} | stack], seen}}
  end

  def handle_event(:end_element, _element_name, {_schemas, [{:skip, _, _} | _], _seen} = state) do
    {:ok, state}
  end

  def handle_event(
        :end_element,
        tag_name,
        {schemas, [{tag_name, attributes, content} | stack], seen}
      ) do
    current = {tag_name, attributes, Enum.reverse(content)}
    [_current_schema | rest_schemas] = schemas

    case stack do
      [] ->
        {:ok, current}

      [parent | rest] ->
        {parent_tag_name, parent_attributes, parent_content} = parent
        parent = {parent_tag_name, parent_attributes, [current | parent_content]}
        {:ok, {rest_schemas, [parent | rest], seen}}
    end
  end

  def handle_event(:end_document, _, state) do
    {:ok, state}
  end

  defp unwrap_schema({:all, schema}), do: schema
  defp unwrap_schema(%{} = schema), do: schema

  def parse_string(data, schema) do
    state = {[schema], [], %{}}

    case Saxy.parse_string(data, __MODULE__, state, []) do
      # the problem is the state now looks like the top level tuple in simple form
      # what we are trying to catch is when we have skipped everything so are returned
      # a schema and an empty stack.
      {:ok, {[^schema], [], _}} ->
        {:error, :not_found}

      {:ok, {:error, _reason} = error} ->
        error

      {:ok, simple_form} ->
        {:ok, simple_form}

      {:error, _reason} = error ->
        error
    end
  end
end
