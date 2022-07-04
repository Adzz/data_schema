defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.CombinabilityRule do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]
  alias Duffel.Link.DataSchema.StringType

  @moduledoc """
  A schema for parsing the OfferInstructionMetadata into combinability rules from LH air
  shop response.
  """

  @association_path [
    "OfferInstructionMetadata",
    "AugmentationPoint",
    "AugPoint",
    "Combinability",
    "Association"
  ]
  xml_schema(
    field:
      {:reference, {["OfferInstructionMetadata"], {:attr, "refs"}}, StringType, optional?: true},
    list_of: {
      :reference_values,
      {@association_path ++ [{:all, "ReferenceValue"}], :text},
      StringType,
      optional?: true
    },
    field: {
      :type,
      {@association_path ++ ["Type"], :text},
      StringType,
      optional?: true
    }
  )
end
