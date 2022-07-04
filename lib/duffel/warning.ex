defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.Warning do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for Warnings in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.StringType

  xml_schema(
    field: {:code, {["Warning"], {:attr, "Code"}}, StringType, optional?: true},
    field: {:owner, {["Warning"], {:attr, "Owner"}}, StringType, optional?: true},
    field: {:type, {["Warning"], {:attr, "Type"}}, StringType, optional?: true},
    field: {:title, {["Warning"], {:attr, "ShortText"}}, StringType, optional?: true},
    field: {:description, {["Warning"], :text}, StringType, optional?: true}
  )
end
