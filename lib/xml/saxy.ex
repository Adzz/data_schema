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

    # By the second G the schema looks different - it doesn't have the G in it.
    # so we could check the prev element and see if has the same tag name. That would
    # work but would mean we didn't handle <A><G /><B /><G /></A> which feels valid.
    # I think it could mean we simplify some bits though as we wouldn't have to
    # track many? What do we NEED to know:

    # * when the parent is closing (so we can use the rest of the schema)
    # - could we instead repeat the schema?
    # * so we can collapse into the parent too though.
    # - Can we unwind the stack - collapse until we don't see
    # * If I expect there to be "many" of a thing from the schema.
    # *

    case Map.pop(unwrap_schema(current_schema), tag_name, :not_found) do
      {:not_found, _} ->
        {:ok, %{state | stack: [{:skip, 0, tag_name} | stack]}}

      {{:all, child_schema}, sibling_schema} ->
        case stack do
          # This case is basically the Nth time around (N > 1)
          [{:parent, parent_tag, _, {^tag_name, _, _}} | _] ->
            attributes =
              Enum.filter(attributes, fn {attr, _value} ->
                Map.get(child_schema, {:attr, attr}, false)
              end)

            tag = {:parent, parent_tag, 0, {tag_name, attributes, []}}
            {:ok, %{state | stack: [tag | stack]}}

          [{parent_tag, _, _} | rest_stack] ->
            attributes =
              Enum.filter(attributes, fn {attr, _value} ->
                Map.get(child_schema, {:attr, attr}, false)
              end)

            tag = {:parent, parent_tag, 0, {tag_name, attributes, []}}

            schemas = [
              %{tag_name => {:all, child_schema}},
              %{tag_name => {:all, sibling_schema}} | rest_schemas
            ]

            {:ok, %{state | stack: [tag | stack], schema: schemas}}
        end

      {child_schema, sibling_schema} ->
        attributes =
          Enum.filter(attributes, fn {attr, _value} ->
            Map.get(child_schema, {:attr, attr}, false)
          end)

        # is an optimisation "if there are no siblings don't include it"?
        # I think it is. Which means it holds for children too..?
        # If there is not child we should skip. Or child should never be empty I would guess?

        # if map_size(sibling_schema) == 0 do
        #   tag = {tag_name, attributes, []}
        #   schemas = [child_schema | rest_schemas]
        #   {:ok, %{state | stack: [tag | stack], schema: schemas}}
        # else
        tag = {tag_name, attributes, []}
        schemas = [child_schema, sibling_schema | rest_schemas]
        {:ok, %{state | stack: [tag | stack], schema: schemas}}
        # end
    end
  end

  def handle_event(:characters, _element, %{stack: [{:skip, _, _} | _]} = state) do
    {:ok, state}
  end

  def handle_event(
        :characters,
        chars,
        %{stack: [{:parent, _, _, {prev, _, _}} | _] = stack} = state
      ) do
    [current_schema | _rest_schemas] = state.schema

    case Map.get(unwrap_schema(Map.get(current_schema, prev, %{})), :text, :not_found) do
      :not_found ->
        {:ok, state}

      true ->
        [{:parent, parent, count, {tag_name, attributes, content}} | stack] = stack
        current = {:parent, parent, count, {tag_name, attributes, [chars | content]}}
        {:ok, %{state | stack: [current | stack]}}
    end
  end

  def handle_event(:characters, chars, %{stack: stack} = state) do
    [current_schema | _rest_schemas] = state.schema

    case Map.get(unwrap_schema(current_schema), :text, :not_found) do
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
        %{stack: [{:parent, tag_name, _, {_, _, _}} | _]} = state
      ) do
    case unwind(state.stack, tag_name, []) do
      # we pop off rest and siblings, should always be 2
      [_ | _] = stack ->
        [_, _ | rest_schema] = state.schema
        {:ok, %{state | stack: stack, schema: rest_schema}}

      final ->
        {:ok, final}
    end

    # raise "p"
  end

  def unwind([{parent_tag, attrs, content}], parent_tag, acc) do
    {parent_tag, attrs, content ++ acc}
  end

  def unwind([{parent_tag, attrs, content} | rest], parent_tag, acc) do
    # This ++  should be fine as content should be small
    [{parent_tag, attrs, content ++ acc} | rest]
  end

  def unwind([{:parent, parent_tag, _, {_, _, _} = child} | rest], parent_tag, acc) do
    unwind(rest, parent_tag, [child | acc])
  end

  def handle_event(
        :end_element,
        tag_name,
        %{stack: [{:parent, _, _, {tag_name, _, _}} | _]} = state
      ) do
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

  defp unwrap_schema({:all, schema}), do: schema
  defp unwrap_schema(%{} = schema), do: schema

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
