defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.PieceDimensionAllowance do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for a Dimension in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.DecimalType
  alias Duffel.Link.DataSchema.StringType

  xml_schema(
    field:
      {:uom, {["PieceDimensionAllowance", "DimensionUOM"], :text},
       {StringType, :cast, [[:downcase]]}, optional?: true},
    field: {
      :category,
      {["PieceDimensionAllowance", "Dimensions", "Category"], :text},
      {StringType, :cast, [[:downcase]]},
      optional?: true
    },
    field: {
      :max,
      {["PieceDimensionAllowance", "Dimensions", "MaxValue"], :text},
      DecimalType,
      optional?: true
    }
  )
end
