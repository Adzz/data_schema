defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.Segment do
  @moduledoc """
  An xml schema for segments in Lufthansa's air shop responses.
  """

  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  # use Duffel.Core.StructAccess

  alias Duffel.Link.DataSchema.Boolean
  alias Duffel.Link.DataSchema.DateType
  alias Duffel.Link.DataSchema.IntegerType
  alias Duffel.Link.DataSchema.NaiveDateTimeType
  alias Duffel.Link.DataSchema.StringType
  alias Duffel.Link.DataSchema.TimeType

  @arrival_datetime [
    field: {:date, {["FlightSegment", "Arrival", "Date"], :text}, DateType},
    field: {:time, {["FlightSegment", "Arrival", "Time"], :text}, TimeType}
  ]

  @departure_datetime [
    field: {:date, {["FlightSegment", "Departure", "Date"], :text}, DateType},
    field: {:time, {["FlightSegment", "Departure", "Time"], :text}, TimeType}
  ]

  xml_schema(
    field: {:sid, {["FlightSegment"], {:attr, "SegmentKey"}}, StringType},
    field:
      {:type, {["FlightSegment", "FlightDetail", "FlightSegmentType"], :text}, StringType,
       optional?: true},
    field: {:aircraft_code, {["FlightSegment", "Equipment", "AircraftCode"], :text}, StringType},
    field: {:aircraft_name, {["FlightSegment", "Equipment", "Name"], :text}, StringType},
    aggregate: {:departure_datetime, @departure_datetime, NaiveDateTimeType},
    field:
      {:departure_terminal, {["FlightSegment", "Departure", "Terminal", "Name"], :text},
       StringType, optional?: true},
    aggregate: {:arrival_datetime, @arrival_datetime, NaiveDateTimeType},
    field:
      {:arrival_terminal, {["FlightSegment", "Arrival", "Terminal", "Name"], :text}, StringType,
       optional?: true},
    # TODO: Check if ClassOfService not or does exists for all farelogix airlines
    field:
      {:cabin_class_code, {["FlightSegment", "ClassOfService", "Code"], :text}, StringType,
       optional?: true},
    field:
      {:cabin_class_marketing_name, {["FlightSegment", "ClassOfService", "MarketingName"], :text},
       StringType, optional?: true},
    field: {:connections, {["FlightSegment"], {:attr, "ConnectInd"}}, Boolean, optional?: true},
    field: {:origin_code, {["FlightSegment", "Departure", "AirportCode"], :text}, StringType},
    field: {:destination_code, {["FlightSegment", "Arrival", "AirportCode"], :text}, StringType},
    field:
      {:distance, {["FlightSegment", "FlightDetail", "FlightDistance", "Value"], :text},
       IntegerType},
    field:
      {:distance_uom, {["FlightSegment", "FlightDetail", "FlightDistance", "UOM"], :text},
       StringType},
    field:
      {:duration, {["FlightSegment", "FlightDetail", "FlightDuration", "Value"], :text},
       StringType},
    field:
      {:marketing_carrier_code, {["FlightSegment", "MarketingCarrier", "AirlineID"], :text},
       StringType, optional?: true},
    field:
      {:marketing_carrier_flight_number,
       {["FlightSegment", "MarketingCarrier", "FlightNumber"], :text}, StringType,
       optional?: true},
    # TODO: Check if Operating Carrier is really a optional element for all airlines
    field:
      {:operating_carrier_code, {["FlightSegment", "OperatingCarrier", "AirlineID"], :text},
       StringType, optional?: true},
    field:
      {:operating_carrier_flight_number,
       {["FlightSegment", "OperatingCarrier", "FlightNumber"], :text}, StringType,
       optional?: true},
    field:
      {:operating_carrier_name, {["FlightSegment", "OperatingCarrier", "Name"], :text},
       StringType, optional?: true},
    field:
      {:stops, {["FlightSegment", "FlightDetail", "Stops", "StopQuantity"], :text}, IntegerType,
       optional?: true}
  )
end
