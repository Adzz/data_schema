defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.OriginDestination do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for OriginDestinations in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.StringType

  # use Duffel.Core.StructAccess

  xml_schema(
    field:
      {:departure_code, {["OriginDestination", "DepartureCode"], :text}, StringType,
       optional?: true},
    field:
      {:arrival_code, {["OriginDestination", "ArrivalCode"], :text}, StringType, optional?: true},
    field:
      {:journeys, {["OriginDestination", "FlightReferences"], :text},
       {StringType, :cast, [[:split]]}, optional?: true},
    field:
      {:sid, {["OriginDestination"], {:attr, "OriginDestinationKey"}}, StringType,
       optional?: true}
  )
end
