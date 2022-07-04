defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.PriceClass do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  A xml schema for Lufthansa's air shopping response.
  """
  alias Duffel.Link.DataSchema.StringType

  # use Duffel.Core.StructAccess

  xml_schema(
    field: {:name, {["PriceClass", "Name"], :text}, StringType, optional?: true},
    field: {:code, {["PriceClass", "Code"], :text}, StringType, optional?: true},
    field: {:sid, {["PriceClass"], {:attr, "PriceClassID"}}, StringType, optional?: true},
    list_of: {
      :descriptions,
      {["PriceClass", "Descriptions", {:all, "Description"}, "Text"], :text},
      StringType,
      optional?: true
    }
  )
end
