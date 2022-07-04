defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.FareRuleDetail do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for FareRuleDetails in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.StringType
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.FareRuleAmount

  xml_schema(
    field: {:metadata_rule_ref, {["Detail"], {:attr, "refs"}}, StringType, optional?: true},
    field: {:type, {["Detail", "Type"], :text}, StringType, optional?: true},
    field: {:application, {["Detail", "Application"], :text}, StringType, optional?: true},
    has_many: {:amounts, ["Detail", "Amounts", {:all, "Amount"}], FareRuleAmount}
  )
end
