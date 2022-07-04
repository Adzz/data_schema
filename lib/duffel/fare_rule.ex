defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.FareRule do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for FareRule in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.Boolean
  alias Duffel.Link.DataSchema.StringType
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.FareRuleDetail

  xml_schema(
    list_of: {
      :ticketing_endorsements,
      {["FareRules", "Ticketing", "Endorsements", {:all, "Endorsement"}], :text},
      StringType,
      optional?: true
    },
    has_many:
      {:details, ["FareRules", "Penalty", "Details", {:all, "Detail"}], FareRuleDetail,
       optional?: true},
    field:
      {:change_fee_ind, {["FareRules", "Penalty"], {:attr, "ChangeFeeInd"}}, Boolean,
       optional?: true},
    field:
      {:cancel_fee_ind, {["FareRules", "Penalty"], {:attr, "CancelFeeInd"}}, Boolean,
       optional?: true}
  )
end
