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
  def handle_event(
        :start_element,
        {tag_name, _},
        %{stack: [{:skip, count, tag_name} | stack]} = state
      ) do
    {:ok, %{state | stack: [{:skip, count + 1, tag_name} | stack]}}
  end

  def handle_event(:start_element, _element, %{stack: [{:skip, _, _} | _]} = state) do
    {:ok, state}
  end

  def handle_event(:start_element, {tag_name, attributes}, %{stack: stack} = state) do
    [current_schema | rest_schemas] = state.schema

    case Map.pop(current_schema, tag_name, :not_found) do
      {:not_found, _} ->
        {:ok, %{state | stack: [{:skip, 0, tag_name} | stack]}}

      {child_schema, sibling_schema} ->
        attributes =
          Enum.filter(attributes, fn {attr, _value} ->
            Map.get(child_schema, {:attr, attr}, false)
          end)

        tag = {tag_name, attributes, []}
        schemas = [child_schema, sibling_schema | rest_schemas]
        {:ok, %{state | stack: [tag | stack], schema: schemas}}
    end
  end

  # REMEMBER! This event will fire multiple times for the same tag, I think it does before
  # and after XML nodes? See the tests for more.

  def handle_event(:characters, _element, %{stack: [{:skip, _, _} | _]} = state) do
    {:ok, state}
  end

  def handle_event(:characters, chars, %{stack: stack} = state) do
    [current_schema | _rest_schemas] = state.schema

    case Map.get(current_schema, :text, :not_found) do
      :not_found ->
        {:ok, state}

      true ->
        [{tag_name, attributes, content} | stack] = stack
        current = {tag_name, attributes, [chars | content]}
        {:ok, %{state | stack: [current | stack]}}
    end
  end

  def handle_event(:cdata, chars, %{stack: stack} = state) do
    [{tag_name, attributes, content} | stack] = stack
    # We probably want to like parse the cdata... But leave like this for now.
    # We also want to only add it if it's in the schema, but until we have a c-data example
    # let's just always include it and see how we need to handle it later.
    current = {tag_name, attributes, [{:cdata, chars} | content]}
    {:ok, %{state | stack: [current | stack]}}
  end

  def handle_event(
        :end_element,
        element_name,
        %{stack: [{:skip, 0, element_name} | stack]} = state
      ) do
    {:ok, %{state | stack: stack}}
  end

  def handle_event(
        :end_element,
        element_name,
        %{stack: [{:skip, count, element_name} | stack]} = state
      ) do
    {:ok, %{state | stack: [{:skip, count - 1, element_name} | stack]}}
  end

  def handle_event(:end_element, _element_name, %{stack: [{:skip, _, _} | _]} = state) do
    {:ok, state}
  end

  def handle_event(
        :end_element,
        tag_name,
        %{stack: [{tag_name, attributes, content} | stack]} = state
      ) do
    current = {tag_name, attributes, Enum.reverse(content)}
    [current_schema | rest_schemas] = state.schema

    case {stack, current_schema} do
      {[], _} ->
        {:ok, current}

      {[parent | rest], _current} ->
        {parent_tag_name, parent_attributes, parent_content} = parent
        parent = {parent_tag_name, parent_attributes, [current | parent_content]}
        {:ok, %{state | stack: [parent | rest], schema: rest_schemas}}
    end
  end

  def handle_event(:end_document, _, state) do
    {:ok, state}
  end

  def parse_string(data, schema) do
    # TODO: once it all works make this a tuple instead of a map for perf.
    # benchmark both approaches.
    state = %{schema: [schema], stack: []}

    case Saxy.parse_string(data, __MODULE__, state, []) do
      # If we are returned an empty stack that means nothing in the XML was in the schema.
      # If we found even one thing we would be returned a simple form node.
      {:ok, %{stack: []}} ->
        {:error, :not_found}

      {:ok, struct} ->
        {:ok, struct}

      {:error, _reason} = error ->
        error
    end
  end
end