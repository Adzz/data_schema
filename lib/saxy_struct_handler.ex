defmodule DataSchema.XMLAttr do
  defstruct [:name, :value]
end

defmodule DataSchema.XMLNode do
  defstruct [:name, :attributes, :content]
end

defmodule DataSchema.SaxyStructHandlerState do
  defstruct [:stack]
end

defmodule DataSchema.Saxy.StructHandler do
  @moduledoc """
  Parses XML into `DataSchema.XMLNodes` and `DataSchema.XMLAttrs`
  """

  @behaviour Saxy.Handler

  @impl true
  def handle_event(:start_element, element, state) do
    {:ok, start_element(element, state)}
  end

  def handle_event(:end_element, element, state) do
    {:ok, end_element(element, state)}
  end

  def handle_event(:characters, element, state) do
    {:ok, characters(element, state)}
  end

  def handle_event(_event_name, _event_data, state) do
    {:ok, state}
  end

  defp start_element({name, attributes}, state) do
    %{stack: stack} = state
    element = make_element(name, attributes, stack)
    %{state | stack: [element | stack]}
  end

  defp end_element(_name, %{stack: [root]} = state) do
    %{state | stack: [reverse_element_content(root)]}
  end

  defp end_element(_name, state) do
    %{stack: stack} = state
    [current, parent | stack] = stack
    current = reverse_element_content(current)
    parent = prepend_element_content(parent, current)
    %{state | stack: [parent | stack]}
  end

  defp characters(characters, state) do
    %{stack: [current | stack]} = state
    current = prepend_element_content(current, characters)
    %{state | stack: [current | stack]}
  end

  # Helpers

  defp prepend_element_content(%{content: content} = current, object) do
    %{current | content: [object | content]}
  end

  defp reverse_element_content(%{content: content} = element) do
    %{element | content: Enum.reverse(content)}
  end

  defp make_element(name, attributes, _stack) do
    attributes = make_attributes(attributes, [])
    %DataSchema.XMLNode{name: name, attributes: attributes, content: []}
  end

  defp make_attributes([], acc), do: Enum.reverse(acc)

  defp make_attributes([{name, value} | attributes], acc) do
    attribute = %DataSchema.XMLAttr{name: name, value: value}
    make_attributes(attributes, [attribute | acc])
  end

  def parse_string(data, options \\ []) do
    state = %DataSchema.SaxyStructHandlerState{stack: []}

    case Saxy.parse_string(data, __MODULE__, state, options) do
      {:ok, %{stack: [document]}} ->
        {:ok, document}

      {:error, _reason} = error ->
        error
    end
  end
end
