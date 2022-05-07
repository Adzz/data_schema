defmodule DataSchema.SaxyStructHandlerAccessor do
  @behaviour DataSchema.DataAccessBehaviour
  @moduledoc """
  Allows for accessing data inside of the following:

  ```elixir
   %DataSchema.XMLNode{
    attributes: [%DataSchema.XMLAttr{name: "price", value: "1"}],
    content: [
      %DataSchema.XMLNode{attributes: [], content: ["mynode"], name: "MyNode"},
      %DataSchema.XMLNode{
        attributes: [],
        content: [
          %DataSchema.XMLNode{attributes: [], content: ["Stuff"], name: "Child"}
        ],
        name: "AnotherNode"
      }
    ],
    name: "ParentNode"
  }
  ```
  """

  @impl true
  # data can be a node (from has_one or top level)
  # or a list (from has_many or list_of)
  def field([_ | _] = list_of_nodes, [node_name | _path]) do
    Enum.find(list_of_nodes, fn child -> Map.fetch!(child, :name) == node_name end)
  end

  def field(data = %DataSchema.XMLNode{}, path) do
    get_field(path, data)
  end

  defp get_field([node_name, "text()"], [_ | _] = child_nodes) do
    child =
      Enum.find(child_nodes, :not_found, fn
        %DataSchema.XMLNode{} = child -> Map.fetch!(child, :name) == node_name
        _text -> false
      end)

    get_field([node_name, "text()"], child)
  end

  defp get_field([node_name, "text()"], data) do
    if Map.fetch!(data, :name) == node_name do
      case Map.fetch!(data, :content) do
        [text] when is_binary(text) ->
          text

        [_ | _] = children ->
          text =
            Enum.reject(children, fn
              %DataSchema.XMLNode{} -> true
              string when is_binary(string) -> false
            end)

          Enum.join(text)
      end
    else
      nil
    end
  end

  defp get_field(["text()" | _rest], _) do
    raise "Invalid path, text() must appear at the end"
  end

  defp get_field(["@" <> attr], [_ | _]) do
    raise "Invalid path; attempting to get attr #{attr} from a list of nodes"
  end

  defp get_field(["@" <> attr | _rest], _) do
    raise "Invalid path; attribute must appear at the end of a path"
  end

  defp get_field([node_name, "@" <> attr_name], data) do
    if Map.fetch!(data, :name) == node_name do
      attrs = Map.fetch!(data, :attributes)

      case attrs do
        [] ->
          nil

        [_ | _] = attrs ->
          attr = Enum.find(attrs, fn attr -> Map.fetch!(attr, :name) == attr_name end)
          Map.fetch!(attr, :value)
      end
    else
      nil
    end
  end

  defp get_field([node_name | rest], [_ | _] = child_nodes) do
    first_matching_child =
      Enum.find(child_nodes, :not_found, fn map ->
        Map.fetch!(map, :name) == node_name
      end)

    case first_matching_child do
      :not_found -> nil
      child -> get_field(rest, Map.fetch!(child, :content))
    end
  end

  defp get_field([node_name | rest], data) do
    case Map.fetch!(data, :name) == node_name do
      # If we ever have a node in our path that isn't in data we stop and return nil.
      false -> nil
      true -> get_field(rest, Map.fetch!(data, :content))
    end
  end

  @impl true
  def list_of(data = %{}, path) do
    raise "list"
  end

  @impl true
  def has_one(data = %{}, path) do
    raise "has one"
  end

  @impl true
  def has_many(data = %{}, path) do
    raise "many"
  end
end
