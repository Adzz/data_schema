defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.Error do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]
  alias Duffel.Link.DataSchema.StringType

  @moduledoc """
  An xml schema for Errors in Lufthansa's air shop responses.
  """
  xml_schema(
    field: {:code, {["Error"], {:attr, "Code"}}, StringType, optional?: true},
    field: {:sid, {["Error"], {:attr, "Owner"}}, StringType, optional?: true},
    field: {:status, {["Error"], {:attr, "Status"}}, StringType, optional?: true},
    field: {:type, {["Error"], {:attr, "Type"}}, StringType, optional?: true},
    field: {:title, {["Error"], {:attr, "ShortText"}}, StringType, optional?: true},
    field: {:description, {["Error"], :text}, StringType, optional?: true}
  )
end
