defmodule Duffel.Link.XMLParsing.Lufthansa.AirShopping do
  import Duffel.Link.XMLSchema, only: [xml_schema: 1]

  @moduledoc """
  A xml schema for Lufthansa's air shopping response.
  """
  alias Duffel.Link.DataSchema.StringType
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.BaggageAllowance
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.CombinabilityRule
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.CurrencyMetadata
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.Error
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.FareGroup
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.Journey
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.Offer
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.OriginDestination
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.Passenger
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.PriceClass
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.RuleMetadata
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.Segment
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.ServiceDefinition
  alias Duffel.Link.XMLParsing.Lufthansa.AirShopping.Warning

  @base_path [
    "SOAP-ENV:Envelope",
    "SOAP-ENV:Body",
    "ns1:XXTransactionResponse",
    "RSP",
    "AirShoppingRS"
  ]
  @metadata_path @base_path ++ ["Metadata", "Other"]
  @fare_group_path @base_path ++ ["DataLists", "FareList", {:all, "FareGroup"}]
  @currency_metadata_path @metadata_path ++
                            [
                              {:all, "OtherMetadata"},
                              "CurrencyMetadatas",
                              {:all, "CurrencyMetadata"}
                            ]
  xml_schema(
    field:
      {:response_sid, {@base_path ++ ["ShoppingResponseID", "ResponseID"], :text}, StringType,
       optional?: true},
    # has_many:
    #   {:baggage_allowances,
    #    @base_path ++ ["DataLists", "BaggageAllowanceList", {:all, "BaggageAllowance"}],
    #    BaggageAllowance, optional?: true},
    # has_many: {:currency_metadata, @currency_metadata_path, CurrencyMetadata, optional?: true},
    # has_many: {:fare_groups, @fare_group_path, FareGroup, optional?: true},
    # has_many:
    #   {:journeys, @base_path ++ ["DataLists", "FlightList", {:all, "Flight"}], Journey,
    #    optional?: true},
    # has_many:
    #   {:offers, @base_path ++ ["OffersGroup", "AirlineOffers", {:all, "Offer"}], Offer,
    #    optional?: true},
    # has_many:
    #   {:origin_destinations,
    #    @base_path ++ ["DataLists", "OriginDestinationList", {:all, "OriginDestination"}],
    #    OriginDestination, optional?: true},
    # has_many:
    #   {:passengers, @base_path ++ ["DataLists", "PassengerList", {:all, "Passenger"}], Passenger,
    #    optional?: true},
    # has_many:
    #   {:rule_metadata,
    #    @base_path ++
    #      [
    #        "Metadata",
    #        "Other",
    #        {:all, "OtherMetadata"},
    #        "RuleMetadatas",
    #        {:all, "RuleMetadata"}
    #      ], RuleMetadata, optional?: true},
    # has_many: {:errors, @base_path ++ ["Errors", {:all, "Error"}], Error, optional?: true},
    has_many:
      {:warnings, @base_path ++ ["Warnings", {:all, "Warning"}], Warning, optional?: true},
    # has_many:
    #   {:service_definitions,
    #    @base_path ++ ["DataLists", "ServiceDefinitionList", {:all, "ServiceDefinition"}],
    #    ServiceDefinition, optional?: true},
    # has_many: {
    #   :price_classes,
    #   @base_path ++ ["DataLists", "PriceClassList", {:all, "PriceClass"}],
    #   PriceClass,
    #   optional?: true
    # },
    # has_many: {
    #   :segments,
    #   @base_path ++ ["DataLists", "FlightSegmentList", {:all, "FlightSegment"}],
    #   Segment,
    #   optional?: true
    # },
    # has_many: {
    #   :combinability_rules,
    #   @base_path ++
    #     [
    #       "Metadata",
    #       "Shopping",
    #       "ShopMetadataGroup",
    #       "Offer",
    #       "OfferInstructionMetadatas",
    #       {:all, "OfferInstructionMetadata"}
    #     ],
    #   CombinabilityRule,
    #   optional?: true
    # }
  )
end
