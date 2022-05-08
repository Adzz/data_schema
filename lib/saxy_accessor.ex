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
  def field(data, path) do
    # These path validations should happen in the schema probably.
    case List.last(path) do
      "text()" -> get_field(path, data)
      "@" <> _ -> get_field(path, data)
      key -> raise "Invalid path; field path must end in text() or an @attr, got #{key}"
    end
  end

  @impl true
  def list_of(data, path) do
    get_list(path, data)
  end

  @impl true
  def has_one(data = %DataSchema.XMLNode{}, path) do
    case invalid_path?(path) do
      true -> raise "Invalid path; has_one must point to an XML node"
      false -> get_nested_node(path, data)
    end
  end

  @impl true
  def has_many(data, path) do
    case invalid_path?(path) do
      true ->
        raise "Invalid path; has_many must point to an XML node"

      false ->
        case get_nested_nodes(path, data) do
          [] -> []
          [_ | _] = nodes -> remove_text(nodes)
          _ -> raise "Invalid path - has_many should point to a list of nodes."
        end
    end
  end

  # list_of

  # Instead of finding the first we need to find _all_ nodes
  defp get_list([node_name | rest], [_ | _] = nodes) do
    nodes
    |> find_nodes(node_name)
    |> Enum.reduce([], fn child, acc ->
      get_list(rest, child.content, acc)
    end)
    |> :lists.reverse()
  end

  defp get_list([node_name | rest], %DataSchema.XMLNode{} = data) do
    get_list(rest, node_content(node_name, data))
  end

  defp get_list(["text()"], [_ | _] = nodes, acc) do
    Enum.reduce(nodes, acc, fn
      text, acc when is_binary(text) ->
        [text | acc]

      %DataSchema.XMLNode{} = data, acc ->
        case data.content do
          [text] when is_binary(text) ->
            [text | acc]

          [_ | _] = children ->
            text = extract_text(children)

            [Enum.join(text) | acc]
        end
    end)
  end

  defp get_list([node_name, "@" <> attr_name], [_ | _] = nodes, acc) do
    Enum.reduce(nodes, acc, fn
      text, acc when is_binary(text) ->
        acc

      %DataSchema.XMLNode{} = data, acc ->
        if data.name == node_name do
          data.attributes
          |> Enum.reduce(acc, fn attr, acc ->
            if attr.name == attr_name do
              [attr.value | acc]
            else
              acc
            end
          end)
        else
          nil
        end
    end)
  end

  defp get_list([node_name | rest], %DataSchema.XMLNode{} = nodes, acc) do
    get_list(rest, node_content(node_name, nodes), acc)
  end

  defp get_list([node_name | rest], [_ | _] = nodes, acc) do
    nodes
    |> find_nodes(node_name)
    |> Enum.reduce(acc, fn child, acc ->
      get_list(rest, child.content, acc)
    end)
  end

  # has_many

  defp get_nested_nodes([node_name], [_ | _] = nodes) do
    find_nodes(nodes, node_name)
  end

  defp get_nested_nodes([node_name | rest], [_ | _] = nodes) do
    case find_node(nodes, node_name) do
      :not_found -> nil
      child -> get_nested_nodes(rest, child.content)
    end
  end

  defp get_nested_nodes([node_name | rest], %DataSchema.XMLNode{} = data) do
    case node_content(node_name, data) do
      nil -> nil
      content -> get_nested_nodes(rest, content)
    end
  end

  # has_one

  defp get_nested_node([node_name], %DataSchema.XMLNode{} = data) do
    if data.name == node_name do
      data
    else
      nil
    end
  end

  defp get_nested_node([node_name], [_ | _] = nodes) do
    case find_node(nodes, node_name) do
      :not_found -> nil
      child -> child
    end
  end

  defp get_nested_node([node_name | rest], [_ | _] = nodes) do
    case find_node(nodes, node_name) do
      :not_found -> nil
      child -> get_nested_node(rest, child.content)
    end
  end

  defp get_nested_node([node_name | rest], %DataSchema.XMLNode{} = data) do
    case node_content(node_name, data) do
      nil -> nil
      content -> get_nested_node(rest, content)
    end
  end

  defp get_field([node_name, "text()"], [_ | _] = child_nodes) do
    case find_node(child_nodes, node_name) do
      :not_found -> nil
      child -> get_field([node_name, "text()"], child)
    end
  end

  defp get_field([node_name, "text()"], %DataSchema.XMLNode{} = data) do
    if data.name == node_name do
      case data.content do
        [text] when is_binary(text) ->
          text

        [_ | _] = children ->
          text = extract_text(children)
          Enum.join(text)
      end
    else
      nil
    end
  end

  # There can be a single "attr" if the schema is a has_one.
  defp get_field(["@" <> attr_name], %DataSchema.XMLNode{} = data) do
    attrs = data.attributes

    case attr(attrs, attr_name) do
      nil -> nil
      attr -> attr.value
    end
  end

  # There can be a single "text" if the schema is a has_one.
  defp get_field(["text()"], %DataSchema.XMLNode{} = data) do
    case data.content do
      [text] when is_binary(text) ->
        text

      [_ | _] = children ->
        text = extract_text(children)
        Enum.join(text)
    end
  end

  defp get_field(["@" <> attr], [_ | _] = d) do
    raise "Invalid path; attempting to get attr #{attr} from a list of nodes"
  end

  defp get_field(["text()"], [_ | _]) do
    raise "Invalid path; attempting to get text from a list of nodes. Specify one or use list_of"
  end

  defp get_field([node_name, "@" <> attr_name], [_ | _] = child_nodes) do
    case find_node(child_nodes, node_name) do
      :not_found ->
        nil

      child ->
        attrs = child.attributes

        case attrs do
          [] ->
            nil

          [_ | _] = attrs ->
            case attr(attrs, attr_name) do
              nil -> nil
              attr -> attr.value
            end
        end
    end
  end

  defp get_field([node_name, "@" <> attr_name], %DataSchema.XMLNode{} = data) do
    if data.name == node_name do
      attrs = data.attributes

      case attrs do
        [] ->
          nil

        [_ | _] = attrs ->
          case attr(attrs, attr_name) do
            nil -> nil
            attr -> attr.value
          end
      end
    else
      nil
    end
  end

  defp get_field([node_name | rest], [_ | _] = child_nodes) do
    case find_node(child_nodes, node_name) do
      :not_found -> nil
      child -> get_field(rest, child.content)
    end
  end

  defp get_field([node_name | rest], %DataSchema.XMLNode{} = data) do
    case node_content(node_name, data) do
      nil -> nil
      content -> get_field(rest, content)
    end
  end

  # This path validation would actually be better to do at compile time, when we create
  # the schema. Let's do that. Would mean we couldn't use data_schema as is, but it would
  # mean no runtime cost.
  defp invalid_path?(path) do
    Enum.any?(path, fn
      "text()" -> true
      "@" <> _ -> true
      _ -> false
    end)
  end

  # Text can be whitespace in between the nodes, or I think it's valid for there to be
  # text in between child nodes.
  defp remove_text(nodes) do
    Enum.filter(nodes, fn
      %DataSchema.XMLNode{} -> true
      string when is_binary(string) -> false
    end)
  end

  defp extract_text(nodes) do
    Enum.reject(nodes, fn
      %DataSchema.XMLNode{} -> true
      string when is_binary(string) -> false
    end)
  end

  defp attr(attrs, attr_name) do
    Enum.find(attrs, fn attr -> attr.name == attr_name end)
  end

  defp attrs(attrs, attr_name) do
    Enum.filter(attrs, fn attr -> attr.name == attr_name end)
  end

  defp find_nodes(nodes, node_name) do
    Enum.filter(nodes, fn
      %DataSchema.XMLNode{} = child -> child.name == node_name
      _text -> false
    end)
  end

  defp find_node(nodes, node_name) do
    Enum.find(nodes, :not_found, fn
      %DataSchema.XMLNode{} = child -> child.name == node_name
      _text -> false
    end)
  end

  defp node_content(node_name, data) do
    case data.name == node_name do
      # If we ever have a node in our path that isn't in data we stop and return nil.
      false -> nil
      true -> data.content
    end
  end
end
