defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.CurrencyMetadata do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for CurrencyMetadata in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.IntegerType
  alias Duffel.Link.DataSchema.StringType

  # use Duffel.Core.StructAccess

  xml_schema(
    field: {:code, {["CurrencyMetadata"], {:attr, "MetadataKey"}}, StringType, optional?: true},
    field: {:decimals, {["CurrencyMetadata", "Decimals"], :text}, IntegerType, optional?: true}
  )
end
