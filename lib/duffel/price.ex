defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.Price do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for a Price in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.DecimalType
  alias Duffel.Link.DataSchema.StringType
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.Tax

  # use Duffel.Core.StructAccess

  xml_schema(
    field: {:base_amount, {["Price", "BaseAmount"], :text}, DecimalType, optional?: true},
    field:
      {:base_currency, {["Price", "BaseAmount"], {:attr, "Code"}}, StringType, optional?: true},
    field:
      {:filed_base_amount, {["Price", "FareFiledIn", "BaseAmount"], :text}, DecimalType,
       optional?: true},
    field:
      {:filed_base_currency, {["Price", "FareFiledIn", "BaseAmount"], {:attr, "Code"}},
       StringType, optional?: true},
    field:
      {:filed_base_nuc, {["Price", "FareFiledIn", "NUC_Amount"], :text}, DecimalType,
       optional?: true},
    field:
      {:filed_exchange_rate, {["Price", "FareFiledIn", "ExchangeRate"], :text}, StringType,
       optional?: true},
    field: {:tax_amount, {["Price", "Taxes", "Total"], :text}, DecimalType, optional?: true},
    field:
      {:tax_currency, {["Price", "Taxes", "Total"], {:attr, "Code"}}, StringType, optional?: true},
    has_many: {:taxes, ["Price", "Taxes", "Breakdown", {:all, "Tax"}], Tax, optional?: true}
  )
end
