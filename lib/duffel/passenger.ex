defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.Passenger do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for passengers in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.JoinWithSpaces
  alias Duffel.Link.DataSchema.StringType

  @given_name [
    list_of:
      {:value, {["Passenger", "Individual", {:all, "GivenName"}], :text}, StringType,
       optional?: true}
  ]
  xml_schema(
    field: {:sid, {["Passenger"], {:attr, "PassengerID"}}, StringType, optional?: true},
    field:
      {:birthdate, {["Passenger", "Individual", "Birthdate"], :text}, StringType, optional?: true},
    field: {
      :family_name,
      {["Passenger", "Individual", "Surname"], :text},
      StringType,
      optional?: true
    },
    field: {:gender, {["Passenger", "Individual", "Gender"], :text}, StringType, optional?: true},
    aggregate: {:given_name, @given_name, JoinWithSpaces, optional?: true},
    field: {
      :title,
      {["Passenger", "Individual", "NameTitle"], :text},
      StringType,
      optional?: true
    },
    field: {:type, {["Passenger", "PTC"], :text}, StringType, optional?: true}
  )
end
