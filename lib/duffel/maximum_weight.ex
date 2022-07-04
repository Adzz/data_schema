defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.MaximumWeight do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for MaximumWeight in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.DecimalType
  alias Duffel.Link.DataSchema.StringType

  xml_schema(
    field: {:maximum_weight, {["MaximumWeight", "Value"], :text}, DecimalType, optional?: true},
    field:
      {:maximum_weight_uom, {["MaximumWeight", "UOM"], :text}, {StringType, :cast, [[:downcase]]},
       optional?: true}
  )
end
