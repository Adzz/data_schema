defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.OfferJourney do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for OfferJourneys in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.StringType

  xml_schema(
    field: {:sid, {["FlightRef"], :text}, StringType, optional?: true},
    field:
      {:origin_destination_sid, {["FlightRef"], {:attr, "ODRef"}}, StringType, optional?: true},
    field:
      {:price_class_sid, {["FlightRef"], {:attr, "PriceClassRef"}}, StringType, optional?: true}
  )
end
