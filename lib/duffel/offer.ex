defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping.Offer do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  An xml schema for Offers in Lufthansa's air shop responses.
  """
  alias Duffel.Link.DataSchema.DecimalType
  alias Duffel.Link.DataSchema.StringType
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.OfferBaggageAllowance
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.OfferItem
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.OfferJourney

  # use Duffel.Core.StructAccess

  @price_guaranteed_by [
    "Offer",
    "TimeLimits",
    "OtherLimits",
    "OtherLimit",
    "PriceGuaranteeTimeLimit",
    "PriceGuarantee"
  ]
  @tax_path [
    "Offer",
    "TotalPrice",
    "DetailCurrencyPrice",
    "Taxes",
    "Total"
  ]
  @ticket_by_path [
    "Offer",
    "TimeLimits",
    "OtherLimits",
    "OtherLimit",
    "TicketByTimeLimit",
    "TicketBy"
  ]
  @expires_at ["Offer", "TimeLimits", "OfferExpiration"]
  xml_schema(
    has_many: {:journeys, ["Offer", "FlightsOverview", {:all, "FlightRef"}], OfferJourney},
    field: {:owner_iata_code, {["Offer"], {:attr, "Owner"}}, StringType},
    field: {:price_guaranteed_by, {@price_guaranteed_by, :text}, StringType, optional?: true},
    field: {:sid, {["Offer"], {:attr, "OfferID"}}, StringType},
    field: {:tax_amount, {@tax_path, :text}, DecimalType, optional?: true},
    field: {:tax_currency, {@tax_path, {:attr, "Code"}}, StringType, optional?: true},
    field: {:ticket_by, {@ticket_by_path, :text}, StringType, optional?: true},
    # This field is a string because later we factor in the point of sale timezone
    # Using Duffel.Link.EctoTypes.TimezoneInUtc.
    field: {:expires_at, {@expires_at, {:attr, "DateTime"}}, StringType, optional?: true},
    field:
      {:total_amount, {["Offer", "TotalPrice", "DetailCurrencyPrice", "Total"], :text},
       DecimalType},
    field: {
      :total_currency,
      {["Offer", "TotalPrice", "DetailCurrencyPrice", "Total"], {:attr, "Code"}},
      StringType
    },
    field: {:fare_type, {["Offer", "Match", "MatchResult"], :text}, StringType, optional?: true},
    has_many: {
      :baggage_allowances,
      ["Offer", {:all, "BaggageAllowance"}],
      OfferBaggageAllowance,
      optional?: true
    },
    has_many: {:items, ["Offer", {:all, "OfferItem"}], OfferItem, optional?: true}
  )
end
