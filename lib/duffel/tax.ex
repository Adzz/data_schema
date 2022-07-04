defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.Tax do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for Tax in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.DecimalType
  alias Duffel.Link.DataSchema.StringType

  xml_schema(
    field: {:amount, {["Tax", "Amount"], :text}, DecimalType, optional?: true},
    field: {:currency, {["Tax", "Amount"], {:attr, "Code"}}, StringType, optional?: true},
    field: {:description, {["Tax", "Description"], :text}, StringType, optional?: true},
    field: {:local_amount, {["Tax", "LocalAmount"], :text}, DecimalType, optional?: true},
    field:
      {:local_currency, {["Tax", "LocalAmount"], {:attr, "Code"}}, StringType, optional?: true},
    field: {:nation_code, {["Tax", "Nation"], :text}, StringType, optional?: true},
    field: {:tax_code, {["Tax", "TaxCode"], :text}, StringType, optional?: true}
  )
end
