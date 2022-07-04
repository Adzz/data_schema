defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.FareGroup do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for FareGroup in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.StringType

  # use Duffel.Core.StructAccess

  xml_schema(
    field: {:sid, {["FareGroup"], {:attr, "ListKey"}}, StringType, optional?: true},
    field: {:fare_code, {["FareGroup", "Fare", "FareCode"], :text}, StringType, optional?: true},
    field:
      {:fare_basis_code, {["FareGroup", "FareBasisCode", "Code"], :text}, StringType,
       optional?: true}
  )
end
