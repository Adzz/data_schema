defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.FareComponent do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for FareComponents in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.StringType
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.FareRule
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.Price

  @cabin_type_path ["FareComponent", "FareBasis", "CabinType"]

  # use Duffel.Core.StructAccess

  xml_schema(
    field:
      {:booking_classes, {["FareComponent", "FareBasis", "RBD"], :text},
       {StringType, :cast, [[:split]]}, optional?: true},
    field:
      {:cabin_class_codes, {@cabin_type_path ++ ["CabinTypeCode"], :text},
       {StringType, :cast, [[:split]]}, optional?: true},
    field:
      {:cabin_class_marketing_names, {@cabin_type_path ++ ["CabinTypeName"], :text},
       {StringType, :cast, [[:split]]}, optional?: true},
    field:
      {:fare_basis_code, {["FareComponent", "FareBasis", "FareBasisCode", "Code"], :text},
       StringType, optional?: true},
    field:
      {:ticket_desig, {["FareComponent", "TicketDesig"], :text}, StringType, optional?: true},
    field:
      {:fare_basis_reference, {["FareComponent", "FareBasis", "FareBasisCode"], {:attr, "refs"}},
       StringType, optional?: true},
    field:
      {:fare_basis_city_pair, {["FareComponent", "FareBasis", "FareBasisCityPair"], :text},
       StringType, optional?: true},
    field:
      {:fare_group_sids, {["FareComponent", "FareBasis", "FareBasisCode"], {:attr, "refs"}},
       {StringType, :cast, [[:split]]}, optional?: true},
    has_one: {:fare_rules, ["FareComponent", "FareRules"], FareRule, optional?: true},
    field:
      {:price_class_sid, {["FareComponent", "PriceClassRef"], :text}, StringType, optional?: true},
    field:
      {:segment_sids, {["FareComponent", "SegmentRefs"], :text}, {StringType, :cast, [[:split]]},
       optional?: true},
    has_one: {:price, ["FareComponent", "Price"], Price, optional?: true}
  )
end
