defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.FareRuleAmount do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for Fare Rule Amount in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.DecimalType
  alias Duffel.Link.DataSchema.StringType

  xml_schema(
    field: {:currency_code, {["Amount", "CurrencyAmountValue"], {:attr, "Code"}}, StringType},
    field: {:total_amount, {["Amount", "CurrencyAmountValue"], :text}, DecimalType},
    field: {:amount_application, {["Amount", "AmountApplication"], :text}, StringType}
  )
end
