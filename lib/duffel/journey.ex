defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.Journey do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for Journey in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.StringType

  xml_schema(
    field: {:sid, {["Flight"], {:attr, "FlightKey"}}, StringType, optional?: true},
    field: {:duration, {["Flight", "Journey", "Time"], :text}, StringType, optional?: true},
    field: {
      :segments,
      {["Flight", "SegmentReferences"], :text},
      {StringType, :cast, [[:split]]},
      optional?: true
    }
  )
end
