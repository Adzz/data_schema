defmodule Duffel.Link.SimpleForm.PathError do
  @moduledoc """
  An exception we can raise when the requested path is incorrect.
  """
  defexception [:message]
end

defmodule Duffel.Link.SimpleForm do
  @moduledoc """
             This module is a low level interface to querying a SimpleForm DOM. It's not really
             intended to be used on its own, but rather exposed via higher level functions like via
             a data_schema accessor.

             SimpleForm is a tuple based representation of XML that looks like this:

                 {node_name, attributes, node_content}

             Where attributes is a keyword list and node_content can be one or more XML nodes or a
             line of text.
             """ && false
  alias Duffel.Link.SimpleForm.SaxyHandler

  @type node_name :: String.t()
  @type attributes :: [{key :: String.t(), value :: String.t()}]
  @type attr_name :: String.t()
  @type xml_data :: String.t()
  @type inner_text :: String.t()
  @typedoc """
  The node content can be a list of just text OR a list of just nodes OR a list of text AND nodes.
  """
  @type node_content :: [inner_text | xml_node]

  @type xml_node :: {node_name, attributes, node_content}
  @type path :: [String.t() | {:all, node_name}]
  @type attr_modifier :: {:attr, attr_name}
  @type modifier :: :text | attr_modifier

  # Errors
  @type multiple_nodes_error :: {:error, {:multiple_nodes, path, [xml_node]}}
  @type node_not_found_error :: {:error, {:node_not_found, path}}
  @type attr_not_found_error :: {:error, {:attr_not_found, path, attr_name}}

  @type t :: xml_node()

  @doc ~S"""
  Handles the sigil `~X` for XMLs.

  It returns a simple form without interpolations and without escape
  characters, except for the escaping of the closing sigil character
  itself.

  ## Examples
      iex> ~X(<node></node>)
      {"node", [], []}
      iex> ~X(<node>f#{o}</node>)
      {"node", [], ["f\#{o}"]}
  """
  defmacro sigil_X(term, modifiers)

  defmacro sigil_X({:<<>>, _meta, [string]}, []) when is_binary(string) do
    quote do
      Duffel.Link.SimpleForm.from_xml!(unquote(string))
    end
  end

  @spec from_xml(xml :: String.t() | Enum.t()) ::
          {:ok, t()} | {:error, Saxy.ParseError.t()}
  def from_xml(xml) when is_binary(xml) do
    Saxy.parse_string(xml, SaxyHandler, [], [])
  end

  def from_xml(xml_stream) do
    Saxy.parse_stream(xml_stream, SaxyHandler, [], [])
  end

  @spec from_xml!(xml :: String.t() | Enum.t()) :: t()
  def from_xml!(xml) do
    case from_xml(xml) do
      {:ok, simple_form} -> simple_form
      {:error, error} -> raise error
    end
  end

  @doc """
  Returns the data at the end of the given path. This works similarly to Access in Elixir
  but differs in some key ways.

  The path is a list of XML node names and by default it is assumed that there should be
  only one of those nodes. If you expect there to be more you can specify you want
  `{:all, node_name}` which will return all of them. There can be arbitrarily many of
  these path keys in a give path.

  If you do not specify `:all` and multiple are found an error will be returned:
  `{:error, {:multiple_nodes, path, all_matching}}`. The user of this function can then
  decide what to do based on that, like raise an error with the path in the error message
  or simply select the first matching node.

  This function returns `{:error, {:not_found, path}` as soon as a node in the path
  does not exist in the data. This lets higher level functions decide whether they wish
  to return `nil` in that case or raise an error if the node is expected to exist.


  ### Examples

      iex> simple_form = ~X(<Node><Child/></Node>)
      ...> SimpleForm.get(simple_form, ["Node", "Child"])
      {"Child", [], []}

      iex> simple_form = ~X(<Node/>)
      ...> SimpleForm.get(simple_form, ["Node", "Child", "Grandchild"])
      {:error, {:node_not_found, ["Node", "Child"]}}

      iex> simple_form = ~X(<Node><Child>1</Child><Child>2</Child></Node>)
      ...> SimpleForm.get(simple_form, ["Node", {:all, "Child"}])
      [{"Child", [], ["1"]}, {"Child", [], ["2"]}]

      iex> simple_form = ~X(<Node><Child/><Child/></Node>)
      ...> SimpleForm.get(simple_form, ["Node", "Child"])
      {:error, {:multiple_nodes, ["Node", "Child"], [{"Child", [], []}, {"Child", [], []}]}}
  """
  @spec get(xml_node, path) ::
          {:ok, xml_node}
          | {:ok, [xml_node]}
          | multiple_nodes_error
          | node_not_found_error
  def get(_simple_form, [{:all, _} | _]) do
    raise Duffel.Link.SimpleForm.PathError,
      message: "Invalid path, XML only supports one element at root level."
  end

  def get(simple_form, path) do
    case List.last(path) do
      {:attr, _} ->
        raise Duffel.Link.SimpleForm.PathError,
          message:
            "Invalid path. Path should point to nested node, to get an attr use get/3 instead."

      :text ->
        raise Duffel.Link.SimpleForm.PathError,
          message:
            "Invalid path. Path should point to nested node, to get the inner text use get/3 instead."

      _ ->
        traverse_path(simple_form, {path, []})
    end
  end

  @doc """
  The same as `Duffel.Link.SimpleForm.get/2` but specifies a modifier for the node of nodes
  pointed to by the given path.

  The available modifiers are:

  * `:text` - Returns all text inside the node(s)
  * `{:attr, attr_name}` - Returns the attribute on the node(s)

  We return `{:error, {:attr_not_found, path, attr}}` when an attr is not there.

  ### Examples

      iex> simple_form = ~X(<Node><Child>Hello</Child></Node>)
      ...> Duffel.Link.SimpleForm.get(simple_form, ["Node", "Child"], :text)
      "Hello"

      iex> simple_form = ~X(<Node/>)
      ...> Duffel.Link.SimpleForm.get(simple_form, ["Node", "Child", "Grandchild"], :text)
      {:error, {:node_not_found, ["Node", "Child"]}}

      iex> simple_form = ~X(<Node><Child/></Node>)
      ...> Duffel.Link.SimpleForm.get(simple_form, ["Node", "Child"], :text)
      ""

      iex> child = {"Child", [], ["1"]}
      ...> simple_form = ~X(<Node><Child>1</Child><Child>1</Child></Node>)
      ...> Duffel.Link.SimpleForm.get(simple_form, ["Node", "Child"], :text)
      {:error, {:multiple_nodes, ["Node", "Child"], [child, child]}}

      iex> simple_form = ~X(<Node/>)
      ...> Duffel.Link.SimpleForm.get(simple_form, ["Node"], {:attr, "thing"})
      {:error, {:attr_not_found, ["Node"], "thing"}}

      iex> simple_form = ~X(<Node thing="1"></Node>)
      ...> Duffel.Link.SimpleForm.get(simple_form, ["Node"], {:attr, "thing"})
      "1"

      iex> simple_form = ~X(<Node><Child thing="1"/><Child thing="2"/></Node>)
      ...> Duffel.Link.SimpleForm.get(simple_form, ["Node", {:all, "Child"}], {:attr, "thing"})
      ["1", "2"]
  """
  @spec get(xml_node, path, modifier) ::
          {:ok, xml_data}
          | {:ok, [xml_data]}
          | multiple_nodes_error
          | node_not_found_error
          | attr_not_found_error
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def get(simple_form, path, :text) do
    case get(simple_form, path) do
      {:error, _} = error ->
        error

      {_node, _attrs, []} ->
        ""

      {_node, _attrs, inner_content} ->
        get_inner_text(inner_content)

      [_ | _] = nodes ->
        # credo:disable-for-lines:11 Credo.Check.Refactor.Nesting
        result =
          Enum.reduce_while(nodes, [], fn
            {:error, _} = error, acc ->
              {:cont, [error | acc]}

            {_node, _attrs, []}, acc ->
              {:cont, ["" | acc]}

            {_node, _attrs, inner_content}, acc ->
              text = get_inner_text(inner_content)
              {:cont, [text | acc]}
          end)

        case result do
          {:error, _details} = error -> error
          found_nodes -> Enum.reverse(found_nodes)
        end
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def get(simple_form, path, {:attr, attr_name}) do
    case get(simple_form, path) do
      {:error, _} = error ->
        error

      {_node, []} ->
        {:error, {:attr_not_found, path, attr_name}}

      {_node, attrs, _} ->
        case get_attr(attrs, attr_name) do
          :not_found -> {:error, {:attr_not_found, path, attr_name}}
          value -> String.trim(value)
        end

      [_ | _] = nodes ->
        # credo:disable-for-lines:11 Credo.Check.Refactor.Nesting
        nodes
        |> Enum.reduce_while([], fn
          {:error, _} = error, acc ->
            {:cont, [error | acc]}

          {_node, attrs, _}, acc ->
            case get_attr(attrs, attr_name) do
              # Should we actually halt here? If the attr is not found on one
              # but is in some, is that a valid XML?? WHO KNOWS
              :not_found -> {:halt, {:error, {:attr_not_found, path, attr_name}}}
              value -> {:cont, [String.trim(value) | acc]}
            end
        end)
        |> case do
          {:error, _} = error -> error
          [_ | _] = attrs -> Enum.reverse(attrs)
        end
    end
  end

  # We are safe to assume that attributes should be uniquely named, so we just get the first.
  # Note we cannot use Keyword.get because the keys are strings in our case.
  defp get_attr([], _attr_name), do: :not_found
  defp get_attr([{attr_name, attr_value} | _rest], attr_name), do: attr_value
  defp get_attr([_ | rest], attr_name), do: get_attr(rest, attr_name)

  defp get_inner_text(inner_content) do
    case Enum.filter(inner_content, &is_binary/1) do
      [] -> ""
      text -> text |> IO.iodata_to_binary() |> String.trim()
    end
  end

  # This can be empty if the node is not there. Like `<Node />`
  defp traverse_path([], {[current | _], seen}) do
    {:error, {:node_not_found, Enum.reverse([current | seen])}}
  end

  defp traverse_path({node_name, _, _} = xml_node, {[node_name], _}) do
    xml_node
  end

  defp traverse_path({node_name, _, children}, {[node_name | rest], seen}) do
    traverse_path(children, {rest, [node_name | seen]})
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp traverse_path([_ | _] = xml_nodes, {[{:all, node_name} | rest], seen}) do
    case find_nodes(xml_nodes, node_name) do
      :not_found ->
        {:error, {:node_not_found, Enum.reverse([{:all, node_name} | seen])}}

      [_ | _] = nodes ->
        # credo:disable-for-lines:9 Credo.Check.Refactor.Nesting
        case rest do
          [] ->
            nodes

          [_ | _] ->
            child_path = {rest, [{:all, node_name} | seen]}
            # credo:disable-for-lines:11 Credo.Check.Refactor.Nesting
            nodes
            # We can't actually stop early here because sometimes one child will have
            # a node but another child wont. And in that case we need to get all children
            # that do have it.
            |> Enum.reduce_while([], fn {_node, _attr, children}, acc ->
              case traverse_path(children, child_path) do
                {:error, {:node_not_found, _}} = error -> {:cont, [error | acc]}
                {:error, _} = error -> {:halt, error}
                result when is_list(result) -> {:cont, [Enum.reverse(result) | acc]}
                result -> {:cont, [result | acc]}
              end
            end)
            |> case do
              {:error, _} = error ->
                error

              [] ->
                {:error, {:node_not_found, Enum.reverse([hd(rest), {:all, node_name} | seen])}}

              [_ | _] = result ->
                # We don't technically _have_ to reverse here, but doing so keeps the order of
                # elements the same as the source data which is probably better.
                result
                |> List.flatten()
                |> Enum.reverse()
            end
        end
    end
  end

  defp traverse_path([_ | _] = xml_nodes, {[node_name | rest], seen}) do
    case find_nodes(xml_nodes, node_name) do
      :not_found ->
        {:error, {:node_not_found, Enum.reverse([node_name | seen])}}

      [{_, _, content} = node] ->
        case rest do
          [] -> node
          _ -> traverse_path(content, {rest, [node_name | seen]})
        end

      [_ | _] = nodes ->
        {:error, {:multiple_nodes, Enum.reverse([node_name | seen]), nodes}}
    end
  end

  defp traverse_path({_node_name, _, _}, {[current | _rest], seen}) do
    {:error, {:node_not_found, Enum.reverse([current | seen])}}
  end

  # Wait shouldn't this be `:not_found` ?
  defp find_nodes([], _node_name), do: []

  # An XML node's content can contain more XML nodes AND lines of text, so we exclude the
  # text when searching for a node.
  defp find_nodes(nodes, node_name) do
    found_nodes = for {^node_name, _, _} = node <- nodes, do: node

    if found_nodes == [], do: :not_found, else: found_nodes
  end
end
