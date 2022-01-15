defmodule DataSchema.OpenApi do
  @doc """
  """
  def schemas_from_open_api_json(json) do
    json
    |> Jason.decode!()
    |> Enum.reduce(%{}, fn
      {"paths", paths_object}, acc ->
        Enum.reduce(paths_object, acc, fn
          {_path, path_item_object}, accum ->
            Enum.reduce(path_item_object, accum, fn path_item_object, accumu ->
              path_item_object(path_item_object, accumu)
            end)
        end)

      {_key, _value}, acc ->
        acc
    end)
  end

  def path_item_object({"get", data}, acc) do
    module_name = Map.fetch!(data, "operationId") |> Macro.camelize() |> IO.inspect()

    fields =
      data
      |> Map.fetch!("responses")
      |> responses_object([])

    Map.put(acc, "GET RESPONSE" <> module_name, fields)
  end

  def path_item_object({"post", data}, acc) do
    module_name = Map.fetch!(data, "operationId") |> Macro.camelize() |> IO.inspect()

    # We also need requestBody from here.

    fields =
      data
      |> Map.fetch!("responses")
      |> responses_object([])

    Map.put(acc, "POST RESPONSE" <> module_name, fields)
  end

  def path_item_object({"put", _data}, acc) do
    acc
  end

  def path_item_object({"delete", _data}, acc) do
    acc
  end

  def path_item_object({"options", _data}, acc) do
    acc
  end

  def path_item_object({new, _data}, _) do
    raise "we got a live one: #{new}"
  end

  def responses_object(%{"200" => data}, acc) do
    data |> response_object(acc)
  end

  def responses_object(%{"default" => _data}, acc) do
    acc
  end

  def responses_object(_, acc) do
    acc
  end

  def response_object(%{"content" => content}, acc) do
    Enum.reduce(content, acc, fn {content_type, media_type_object}, accu ->
      media_type_object(content_type, media_type_object, accu)
    end)
  end

  def media_type_object("application/json", media_type_object, acc) do
    media_type_object |> Map.fetch!("schema") |> schema_object(acc)
  end

  def media_type_object(_content_type, _media_type_object, acc) do
    acc
  end

  defp schema_object(%{"type" => "string", "enum" => values}, _acc) do
    values
  end

  defp schema_object(%{"type" => "object", "properties" => properties}, acc) do
    # properties |> Map.keys() |> IO.inspect(limit: :infinity, label: "xxxxxxxxx")
    parse_properties(properties, acc)
  end

  defp schema_object(%{"type" => "array", "items" => %{"properties" => properties}}, acc) do
    parse_properties(properties, acc)
  end

  defp schema_object(%{"type" => "array", "items" => items}, acc) do
    schema_object(items, acc)
  end

  defp parse_properties(properties, acc) do
    properties
    |> Enum.reduce(acc, fn
      {key, %{"oneOf" => one}}, accu ->
        1

      {key, %{"allOf" => all}}, accu ->
        Enum.reduce(all, accu, fn item, acum ->
          if Map.get(item, "type") do
            schema_object(item, acum)
          else
            acum
          end
        end)

      {key, value}, accu ->
        case value["type"] do
          "object" -> [{:has_one, {String.to_atom(key), key, schema_object(value, [])}} | accu]
          "array" -> [{:has_many, {String.to_atom(key), key, schema_object(value, [])}} | accu]
          "boolean" -> [{:field, {String.to_atom(key), key, "boolean"}} | accu]
          "integer" -> [{:field, {String.to_atom(key), key, "integer"}} | accu]
          "number" -> [{:field, {String.to_atom(key), key, "integer"}} | accu]
          "string" -> [{:field, {String.to_atom(key), key, "string"}} | accu]
          nil -> raise "OH NO #{inspect(value)}"
        end
    end)
  end

  # %{
  #   "description" =>
  #     "The metadata varies by the type of service. It includes further data\nabout the service. For example, for baggages, it may have data about\nsize and weight restrictions.\n",
  #   "oneOf" => [
  #     %{
  #       "description" => "An object containing metadata about the service, like the maximum weight and dimensions of the baggage.",
  #       "properties" => %{
  #         "maximum_depth_cm" => %{
  #           "description" => "The maximum depth that the baggage can have in centimetres",
  #           "example" => 75,
  #           "nullable" => true,
  #           "type" => "number"
  #         },
  #         "maximum_height_cm" => %{
  #           "description" => "The maximum height that the baggage can have in centimetres",
  #           "example" => 90,
  #           "nullable" => true,
  #           "type" => "number"
  #         },
  #         "maximum_length_cm" => %{
  #           "description" => "The maximum length that the baggage can have in centimetres",
  #           "example" => 90,
  #           "nullable" => true,
  #           "type" => "number"
  #         },
  #         "maximum_weight_kg" => %{
  #           "description" => "The maximum weight that the baggage can have in kilograms",
  #           "example" => 23,
  #           "nullable" => true,
  #           "type" => "number"
  #         },
  #         "type" => %{
  #           "description" => "The type of the baggage",
  #           "enum" => ["checked", "carry_on"],
  #           "example" => "checked",
  #           "type" => "string"
  #         }
  #       },
  #       "title" => "Service Metadata for a Baggage",
  #       "type" => "object"
  #     }
  #   ]
  # }
end
