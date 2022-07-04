defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.PieceAllowance do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  A Lufthansa schema for PieceAllowances, found in an air_shopping response.
  """
  alias Duffel.Link.DataSchema.IntegerType
  alias Duffel.Link.DataSchema.StringType
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.MaximumWeight
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.PieceDimensionAllowance

  xml_schema(
    field: {
      :applicable_bag,
      {["PieceAllowance", "ApplicableBag"], :text},
      StringType,
      optional?: true
    },
    field: {
      :applicable_party,
      {["PieceAllowance", "ApplicableParty"], :text},
      {StringType, :cast, [[:downcase]]}
    },
    field: {
      :total_quantity,
      {["PieceAllowance", "TotalQuantity"], :text},
      IntegerType,
      optional?: true
    },
    has_many:
      {:weights,
       [
         "PieceAllowance",
         "PieceMeasurements",
         {:all, "PieceWeightAllowance"},
         "MaximumWeight"
       ], MaximumWeight, optional?: true},
    has_many: {
      :dimensions,
      ["PieceAllowance", "PieceMeasurements", {:all, "PieceDimensionAllowance"}],
      PieceDimensionAllowance,
      optional?: true
    }
  )
end
