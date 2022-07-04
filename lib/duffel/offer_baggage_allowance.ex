defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.OfferBaggageAllowance do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for OfferBaggageAllowances in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.StringType

  xml_schema(
    field: {
      :baggage_allowance_sid,
      {["BaggageAllowance", "BaggageAllowanceRef"], :text},
      StringType,
      optional?: true
    },
    field: {
      :journey_sids,
      {["BaggageAllowance", "FlightRefs"], :text},
      {StringType, :cast, [[:split]]},
      optional?: true
    },
    field: {
      :passenger_ids,
      {["BaggageAllowance", "PassengerRefs"], :text},
      {StringType, :cast, [[:split]]},
      optional?: true
    }
  )
end
