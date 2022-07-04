defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.OfferItem do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for OfferItems in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.Boolean
  alias Duffel.Link.DataSchema.DecimalType
  alias Duffel.Link.DataSchema.StringType
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.FareDetail
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.OfferItemService

  # use Duffel.Core.StructAccess

  @total_path [
    "OfferItem",
    "TotalPriceDetail",
    "TotalAmount",
    "DetailCurrencyPrice",
    "Total"
  ]

  xml_schema(
    field: {:mandatory, {["OfferItem"], {:attr, "MandatoryInd"}}, Boolean, optional?: true},
    field: {:sid, {["OfferItem"], {:attr, "OfferItemID"}}, StringType, optional?: true},
    field: {:total_amount, {@total_path, :text}, DecimalType, optional?: true},
    field: {:total_currency, {@total_path, {:attr, "Code"}}, StringType, optional?: true},
    has_many: {:fare_details, ["OfferItem", {:all, "FareDetail"}], FareDetail, optional?: true},
    has_many: {:services, ["OfferItem", {:all, "Service"}], OfferItemService, optional?: true}
  )
end
