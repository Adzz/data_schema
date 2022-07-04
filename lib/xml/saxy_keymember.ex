defmodule DataSchema.XML.SaxyKeymember do
  @moduledoc """
  Experiments in efficient XML parsing. This is a Saxy handler that only keeps elements
  that appear in a data schema. It builds a simple form representation of the XML, but
  only puts in elements and attributes that exist in a schema. Check the tests for examples
  of what the schema should look like (it should be a tree that mirrors the structure).
  """

  # BENCH

  # This approach was found to be faster and is simpler so we are keeping it.

  # Benchmarking keymember ...
  # Benchmarking normal ...

  # Name                ips        average  deviation         median         99th %
  # keymember          3.12      320.58 ms     ±1.14%      320.73 ms      329.85 ms
  # normal             2.77      360.93 ms     ±1.27%      360.95 ms      371.65 ms

  # Comparison:
  # keymember          3.12
  # normal             2.77 - 1.13x slower +40.35 ms

  # Memory usage statistics:

  # Name         Memory usage
  # keymember       132.53 MB
  # normal          141.17 MB - 1.07x memory usage +8.64 MB

  # **All measurements for memory usage were the same**

  # Reduction count statistics:

  # Name              average  deviation         median         99th %
  # keymember         16.12 M     ±0.04%        16.12 M        16.13 M
  # normal            16.23 M     ±0.04%        16.23 M        16.25 M

  # Comparison:
  # keymember         16.12 M
  # normal            16.23 M - 1.01x reduction count +0.111 M

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
        {schemas, [{:skip, count, tag_name} | stack]}
      ) do
    {:ok, {schemas, [{:skip, count + 1, tag_name} | stack]}}
  end

  def handle_event(:start_element, _element, {_, [{:skip, _, _} | _]} = state) do
    {:ok, state}
  end

  def handle_event(:start_element, {tag_name, attributes}, {schemas, stack}) do
    [current_schema | rest_schemas] = schemas

    case Map.pop(unwrap_schema(current_schema), tag_name, :not_found) do
      {:not_found, _} ->
        with [{_, _, children} | _] <- stack,
             true <- List.keymember?(children, tag_name, 0) do
          {:stop, {:error, "Saw many #{tag_name}'s expected one!"}}
        else
          # If the stack is empty and we are skipping that means we have skipped the root
          # node, and therefore the whole document. So we can stop parsing immediately as
          # we know the values we want are not here!
          [] ->
            {:stop, {:error, :not_found}}

          false ->
            {:ok, {schemas, [{:skip, 0, tag_name} | stack]}}
        end

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
            {:ok, {schemas, [tag | stack]}}

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

            {:ok, {schemas, [tag | stack]}}
        end

      {child_schema, sibling_schema} ->
        attributes =
          Enum.filter(attributes, fn {attr, _value} ->
            Map.get(child_schema, {:attr, attr}, false)
          end)

        # Do we put it in here? we only need siblings?
        tag = {tag_name, attributes, []}
        schemas = [child_schema, sibling_schema | rest_schemas]
        {:ok, {schemas, [tag | stack]}}
    end
  end

  def handle_event(:characters, _element, {_, [{:skip, _, _} | _]} = state) do
    {:ok, state}
  end

  def handle_event(:characters, chars, {schemas, stack} = state) do
    [current_schema | _rest_schemas] = schemas

    case Map.get(unwrap_schema(current_schema), :text, :not_found) do
      :not_found ->
        {:ok, state}

      true ->
        [{tag_name, attributes, content} | stack] = stack
        current = {tag_name, attributes, [chars | content]}
        {:ok, {schemas, [current | stack]}}
    end
  end

  def handle_event(:cdata, chars, {schemas, stack}) do
    [{tag_name, attributes, content} | stack] = stack
    # We probably want to like parse the cdata... But leave like this for now.
    # We also want to only add it if it's in the schema, but until we have a c-data example
    # let's just always include it and see how we need to handle it later.
    current = {tag_name, attributes, [{:cdata, chars} | content]}
    {:ok, {schemas, [current | stack]}}
  end

  def handle_event(:end_element, element_name, {schemas, [{:skip, 0, element_name} | stack]}) do
    {:ok, {schemas, stack}}
  end

  def handle_event(
        :end_element,
        element_name,
        {schemas, [{:skip, count, element_name} | stack]}
      ) do
    {:ok, {schemas, [{:skip, count - 1, element_name} | stack]}}
  end

  def handle_event(:end_element, _element_name, {_schemas, [{:skip, _, _} | _]} = state) do
    {:ok, state}
  end

  def handle_event(
        :end_element,
        tag_name,
        {schemas, [{tag_name, attributes, content} | stack]}
      ) do
    current = {tag_name, attributes, Enum.reverse(content)}
    [_current_schema | rest_schemas] = schemas

    case stack do
      [] ->
        {:ok, current}

      [parent | rest] ->
        {parent_tag_name, parent_attributes, parent_content} = parent
        parent = {parent_tag_name, parent_attributes, [current | parent_content]}
        {:ok, {rest_schemas, [parent | rest]}}
    end
  end

  def handle_event(:end_document, _, state) do
    {:ok, state}
  end

  defp unwrap_schema({:all, schema}), do: schema
  defp unwrap_schema(%{} = schema), do: schema

  def parse_string(data, schema) do
    state = {[schema], []}

    case Saxy.parse_string(data, __MODULE__, state, []) do
      {:ok, {:error, _reason} = error} ->
        error

      {:ok, simple_form} ->
        {:ok, simple_form}

      {:error, _reason} = error ->
        error
    end
  end
end