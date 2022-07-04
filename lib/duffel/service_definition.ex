defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.ServiceDefinition do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  A xml schema for Lufthansa's air shopping ServiceDefinition response.
  """
  alias Duffel.Link.DataSchema.IntegerType
  alias Duffel.Link.DataSchema.StringType

  xml_schema(
    field:
      {:baggage_allowance_ref, {["ServiceDefinition", "BaggageAllowanceRef"], :text}, StringType,
       optional?: true},
    list_of:
      {:descriptions,
       {["ServiceDefinition", "Descriptions", {:all, "Description"}, "Text"], :text}, StringType,
       optional?: true},
    field: {:name, {["ServiceDefinition", "Name"], :text}, StringType, optional?: true},
    field: {:owner, {["ServiceDefinition"], {:attr, "Owner"}}, StringType, optional?: true},
    field:
      {:sid, {["ServiceDefinition"], {:attr, "ServiceDefinitionID"}}, StringType, optional?: true},
    field:
      {:subcode, {["ServiceDefinition", "Encoding", "SubCode"], :text}, StringType,
       optional?: true},
    field:
      {:minimum_quantity,
       {["ServiceDefinition", "Detail", "ServiceItemQuantityRules", "MinimumQuantity"], :text},
       IntegerType, optional?: true},
    field:
      {:maximum_quantity,
       {["ServiceDefinition", "Detail", "ServiceItemQuantityRules", "MaximumQuantity"], :text},
       IntegerType, optional?: true}
  )
end
