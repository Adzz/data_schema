defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.WeightAllowance do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for WeightAllowances in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.StringType
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.MaximumWeight

  xml_schema(
    field:
      {:applicable_party, {["WeightAllowance", "ApplicableParty"], :text},
       {StringType, :cast, [[:downcase]]}, optional?: true},
    has_many: {:weights, ["WeightAllowance", {:all, "MaximumWeight"}], MaximumWeight}
  )
end
