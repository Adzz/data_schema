defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.BaggageAllowance do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for baggage allowances in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.StringType
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.PieceAllowance
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.WeightAllowance

  xml_schema(
    field: {:sid, {["BaggageAllowance"], {:attr, "BaggageAllowanceID"}}, StringType},
    field: {
      :baggage_determining_carrier_code,
      {["BaggageAllowance", "BaggageDeterminingCarrier", "AirlineID"], :text},
      StringType,
      optional?: true
    },
    field:
      {:category, {["BaggageAllowance", "BaggageCategory"], :text},
       {StringType, :cast, [[:downcase]]}, optional?: true},
    field:
      {:descriptions,
       {[
          "BaggageAllowance",
          "AllowanceDescription",
          "Descriptions",
          "Description",
          "Text"
        ], :text}, StringType, optional?: true},
    has_many:
      {:piece_allowances, ["BaggageAllowance", {:all, "PieceAllowance"}], PieceAllowance,
       optional?: true},
    has_many: {
      :weight_allowances,
      ["BaggageAllowance", {:all, "WeightAllowance"}],
      WeightAllowance,
      optional?: true
    }
  )
end
