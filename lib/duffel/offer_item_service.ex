defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.OfferItemService do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for OfferItemServices in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.StringType

  # use Duffel.Core.StructAccess

  xml_schema(
    field:
      {:journey_sids, {["Service", "FlightRefs"], :text}, {StringType, :cast, [[:split]]},
       optional?: true},
    field:
      {:passenger_sids, {["Service", "PassengerRefs"], :text}, {StringType, :cast, [[:split]]},
       optional?: true},
    field:
      {:segment_sids, {["Service", "ServiceDefinitionRef"], {:attr, "SegmentRefs"}},
       {StringType, :cast, [[:split]]}, optional?: true},
    field:
      {:service_definition_sid, {["Service", "ServiceDefinitionRef"], :text}, StringType,
       optional?: true},
    # We only ever seem to see this in BA? So maybe don't need it for lufthansa?
    field: {:service_sid, {["Service", "ServiceRef"], :text}, StringType, optional?: true},
    field: {:sid, {["Service"], {:attr, "ServiceID"}}, StringType, optional?: true}
  )
end
