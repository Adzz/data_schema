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
  # don't stop skipping when that duplicate tag closes. But we don't really want to keep
  # a stack of all elements that we skip as that defeats the point of skipping. So instead
  # if we open a tag that has the same name as the parent "skipped" tag, we duplicate it
  # so that when we close it and pop the skip off the tag it still all works.
  def handle_event(
        :start_element,
        {tag_name, _},
        %{stack: [{:skip, tag_name} | _] = stack} = state
      ) do
    {:ok, %{state | stack: [{:skip, tag_name} | stack]}}
  end

  def handle_event(:start_element, _element, %{stack: [{:skip, _} | _]} = state) do
    {:ok, state}
  end

  def handle_event(:start_element, {tag_name, attributes}, %{stack: stack} = state) do
    # Check if we are on the path. If so great create the DOM. If not then don't

    case Map.get(state.schema, tag_name, :not_found) do
      :not_found ->
        {:ok, %{state | stack: [{:skip, tag_name} | stack]}}

      _ ->
        tag = {tag_name, attributes, []}
        {:ok, %{state | stack: [tag | stack]}}
    end
  end

  def handle_event(:characters, _element, %{stack: [{:skip, _} | _]} = state) do
    {:ok, state}
  end

  def handle_event(:characters, chars, %{stack: stack} = state) do
    [{tag_name, attributes, content} | stack] = stack
    current = {tag_name, attributes, [chars | content]}
    {:ok, %{state | stack: [current | stack]}}
  end

  def handle_event(:cdata, chars, %{stack: stack} = state) do
    [{tag_name, attributes, content} | stack] = stack
    # We probably want to like parse the cdata... But leave like this for now.
    current = {tag_name, attributes, [{:cdata, chars} | content]}

    {:ok, %{state | stack: [current | stack]}}
  end

  def handle_event(:end_element, element_name, %{stack: [{:skip, element_name} | stack]} = state) do
    {:ok, %{state | stack: stack}}
  end

  def handle_event(:end_element, _element_name, %{stack: [{:skip, _} | _]} = state) do
    {:ok, state}
  end

  def handle_event(
        :end_element,
        tag_name,
        %{stack: [{tag_name, attributes, content} | stack]} = state
      ) do
    current = {tag_name, attributes, Enum.reverse(content)}

    case stack do
      [] ->
        {:ok, current}

      [parent | rest] ->
        {parent_tag_name, parent_attributes, parent_content} = parent
        parent = {parent_tag_name, parent_attributes, [current | parent_content]}
        {:ok, %{state | stack: [parent | rest]}}
    end
  end

  def handle_event(:end_document, _, state) do
    {:ok, state}
  end

  def parse_string(data, schema) do
    state = %{schema: schema, stack: []}

    case Saxy.parse_string(data, __MODULE__, state, []) do
      {:ok, struct} ->
        {:ok, struct}

      {:error, _reason} = error ->
        error
    end
  end
end
