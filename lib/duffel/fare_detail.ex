defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.FareDetail do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for FareDetails in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.StringType
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.FareComponent
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.Price

  # use Duffel.Core.StructAccess

  xml_schema(
    field:
      {:fare_indicator_code, {["FareDetail", "FareIndicatorCode"], :text}, StringType,
       optional?: true},
    field:
      {:passenger_sids, {["FareDetail", "PassengerRefs"], :text}, {StringType, :cast, [[:split]]},
       optional?: true},
    list_of:
      {:remarks, {["FareDetail", "Remarks", {:all, "Remark"}], :text}, StringType,
       optional?: true},
    has_many:
      {:fare_components, ["FareDetail", {:all, "FareComponent"}], FareComponent, optional?: true},
    has_one: {:price, ["FareDetail", "Price"], Price, optional?: true}
  )
end
