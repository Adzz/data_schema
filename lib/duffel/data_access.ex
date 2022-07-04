defmodule Duffel.Link.SimpleForm.DataAccess.PathError do
  @moduledoc """
  An exception we can raise when the requested path and modifier is incorrect.
  """
  defexception [:message]
end

defmodule Duffel.Link.SimpleForm.DataAccess do
  @moduledoc """
             Implementation of `DataSchema.DataAccessBehaviour` so
             you can create schemas over the  SimpleForm structure.
             This module is meant to be called by DataSchemas and is not
             meant to be used directly. If you feel the need to consider
             using a schema or calling `SimpleForm.get/2` directly.
             Calling it directly will likely miss out on some useful compile
             time validations on the paths in the schemas.
             """ && false

  alias Duffel.Link.SimpleForm
  alias Duffel.Link.SimpleForm.DataAccess.PathError

  @behaviour DataSchema.DataAccessBehaviour

  @impl true
  def field(simple_form, {path, modifier}) do
    result = SimpleForm.get(simple_form, path, modifier)

    case ensure_one!(result, :field, path) do
      "" -> nil
      {:error, {:node_not_found, _not_found_path}} -> nil
      {:error, {:attr_not_found, _not_found_path, _attr_name}} -> nil
      result -> result
    end
  end

  @impl true
  def list_of(simple_form, {path, modifier}) do
    simple_form
    |> SimpleForm.get(path, modifier)
    |> ensure_list!(path, :list_of)
    |> Enum.map(fn
      "" -> nil
      item -> item
    end)
    |> Enum.reject(fn
      {:error, {:node_not_found, _path}} -> true
      _item -> false
    end)
  end

  def list_of(simple_form, path) when is_list(path) do
    simple_form
    |> SimpleForm.get(path)
    |> ensure_list!(path, :list_of)
    |> Enum.reject(fn
      {:error, {:node_not_found, _path}} -> true
      _item -> false
    end)
  end

  @impl true
  def has_one(_simple_form, {_, _modifier} = path) do
    raise PathError,
          "\n\nA :has_one field should point to a nested XML node only.\n" <>
            "The path should not include the :text or :attr modifiers.\n" <>
            "Path received was: #{inspect(path)}"
  end

  def has_one(simple_form, path) when is_list(path) do
    simple_form
    |> SimpleForm.get(path)
    |> ensure_one!(:has_one, path)
    |> then(fn
      {:error, {:node_not_found, _path}} ->
        nil

      result ->
        result
    end)
  end

  @impl true
  def has_many(simple_form, path) when is_list(path) do
    simple_form
    |> SimpleForm.get(path)
    |> ensure_list!(path, :has_many)
    |> Enum.reject(fn
      {:error, {:node_not_found, _path}} -> true
      _item -> false
    end)
  end

  defp ensure_list!(result, path, field_type) do
    case result do
      # if the complete path matches means: only
      # the last fragment, the target node, was not found
      {:error, {:node_not_found, ^path}} ->
        # Should this be nil or an empty list/
        []

      {:error, {:node_not_found, _not_found_path}} ->
        []

      {:error, {:attr_not_found, not_found_path, attr_name}} ->
        raise PathError,
              "Attribute #{inspect(attr_name)} was not found in #{inspect(not_found_path)}"

      # Wait, a multiple nodes error?! But we want a list! How can this happen?!
      # Hilariously we can get this error because we want users to be explicit about
      # the expectations in their data. If a user wants all grandchildren for example, the
      # path should be `["A", {:all, "B"}, {:all, "C"}]`. This says "I expect there to be
      # more than one B sometimes".
      # If you instead write `["A", "B", {:all, "C"}]` you will get an error if there is
      # more than one `"B"`.
      {:error, {:multiple_nodes, path, _nodes}} ->
        last_node = List.last(path)

        raise PathError,
              "\n\nThere were multiple #{last_node} nodes, but the path " <>
                "only expected one.\nIf you expect more than one child, use {:all, #{last_node}}"

      result when is_list(result) ->
        result

      binary when is_binary(binary) ->
        last_node = path |> List.last() |> inspect()

        raise PathError,
              "The path of #{field_type} should target multiple tags, " <>
                "got #{last_node}. Please use {:all, #{last_node}} instead"

      {_, _, _} ->
        wrong_path = path |> List.last() |> inspect()

        raise PathError,
              "The path of #{field_type} should target multiple tags, " <>
                "got #{wrong_path}. Please use {:all, #{wrong_path}} instead"
    end
  end

  defp ensure_one!(result, field, path) do
    case result do
      result when is_list(result) ->
        wrong_path = path |> List.last() |> inspect()

        raise PathError,
              "The path of a :#{field} should target a single tag or attr, got #{wrong_path}"

      {:error, {:multiple_nodes, path, _nodes}} ->
        last_node = List.last(path)

        raise PathError,
              "\n\nThere were multiple #{last_node} nodes, but the path " <>
                "only expected one.\nIf you expect more than one child, use {:all, #{last_node}}"

      result ->
        result
    end
  end
end
