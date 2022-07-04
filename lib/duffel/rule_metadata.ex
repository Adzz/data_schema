defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.RuleMetadata do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for RuleMetadata in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.StringType

  xml_schema(
    field:
      {:metadata_key, {["RuleMetadata"], {:attr, "MetadataKey"}}, StringType, optional?: true},
    field: {:type, {["RuleMetadata", "RuleID"], :text}, StringType, optional?: true},
    field:
      {:allowed, {["RuleMetadata", "Values", "Value", "Instruction"], :text},
       &{:ok, &1 == "Allowed"}, optional?: true}
  )
end
