defmodule DecimalType do
  @behaviour DataSchema.CastBehaviour

  def cast(value) when is_binary(value), do: {:ok, Decimal.new(value)}
  def cast(value) when is_integer(value), do: {:ok, Decimal.new(value)}
  def cast(value) when is_float(value), do: {:ok, Decimal.from_float(value)}
  def cast(nil), do: {:ok, nil}
  def cast(value), do: {:error, "Value can't be cast to Decimal: #{inspect(value)}"}
end

defmodule IntegerType do
  @behaviour DataSchema.CastBehaviour

  def cast(nil), do: {:ok, nil}
  def cast(value) when is_binary(value), do: {:ok, String.to_integer(value)}
  def cast(value) when is_integer(value), do: {:ok, value}
  def cast(value), do: {:error, "Can't be cast to integer: #{inspect(value)}"}
end

defmodule StringType do
  @behaviour DataSchema.CastBehaviour

  def cast(nil), do: {:ok, nil}
  def cast(value) when is_binary(value), do: {:ok, value}
  def cast(value), do: {:ok, to_string(value)}
end

defmodule Boolean do
  @behaviour DataSchema.CastBehaviour
  @impl true
  def cast("true"), do: {:ok, true}
  def cast("false"), do: {:ok, false}
  def cast(nil), do: {:ok, nil}
end

defmodule JoinWithSpaces do
  @behaviour DataSchema.CastBehaviour
  @impl true
  def cast(nil), do: {:ok, nil}
  def cast(x), do: {:ok, Enum.join(x, " ")}
end

defmodule StringSplitOnSpace do
  @behaviour DataSchema.CastBehaviour
  @impl true
  def cast(nil), do: {:ok, nil}
  def cast(x), do: {:ok, String.split(x)}
end

defmodule BlankAsNil do
  @behaviour DataSchema.CastBehaviour

  @impl true
  def cast(""), do: {:ok, nil}
  def cast(nil), do: {:ok, nil}
  def cast(value) when is_binary(value), do: {:ok, value}
end

defmodule Downcase do
  @behaviour DataSchema.CastBehaviour
  @impl true
  def cast(nil), do: {:ok, nil}
  def cast(value) when is_binary(value), do: {:ok, String.downcase(value)}
end

defmodule Warning do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field: {:code, ["Warning", "@Code"], StringType, optional?: true},
    field: {:owner, ["Warning", "@Owner"], StringType, optional?: true},
    field: {:type, ["Warning", "@Type"], StringType, optional?: true},
    field: {:title, ["Warning", "@ShortText"], StringType, optional?: true},
    field: {:description, ["Warning", "text()"], StringType, optional?: true}
  )
end

defmodule Error do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field: {:code, ["Error", "@Code"], StringType, optional?: true},
    field: {:sid, ["Error", "@Owner"], StringType, optional?: true},
    field: {:status, ["Error", "@Status"], StringType, optional?: true},
    field: {:type, ["Error", "@Type"], StringType, optional?: true},
    field: {:title, ["Error", "@ShortText"], StringType, optional?: true},
    field: {:description, ["Error", "text()"], StringType, optional?: true}
  )
end

defmodule Weight do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field:
      {:maximum_weight, ["PieceWeightAllowance", "MaximumWeight", "Value", "text()"], Downcase},
    field:
      {:maximum_weight_uom, ["PieceWeightAllowance", "MaximumWeight", "UOM", "text()"], Downcase}
  )
end

defmodule Dimension do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field: {:uom, ["PieceDimensionAllowance", "DimensionUOM", "text()"], Downcase},
    field: {:category, ["PieceDimensionAllowance", "Dimensions", "Category", "text()"], Downcase},
    field: {:max, ["PieceDimensionAllowance", "Dimensions", "MaxValue", "text()"], StringType}
  )
end

defmodule PieceAllowance do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field:
      {:applicable_bag, ["PieceAllowance", "ApplicableBag", "text()"], StringType,
       optional?: true},
    field: {:applicable_party, ["PieceAllowance", "ApplicableParty", "text()"], Downcase},
    field:
      {:total_quantity, ["PieceAllowance", "TotalQuantity", "text()"], IntegerType,
       optional?: true},
    has_many:
      {:weights, ["PieceAllowance", "PieceMeasurements", "PieceWeightAllowance"], Weight,
       optional?: true},
    has_many:
      {:dimensions, ["PieceAllowance", "PieceMeasurements", "PieceDimensionAllowance"], Dimension,
       optional?: true}
  )
end

defmodule MaxWeight do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field: {:maximum_weight, ["MaximumWeight", "Value", "text()"], Downcase},
    field: {:maximum_weight_uom, ["MaximumWeight", "UOM", "text()"], Downcase}
  )
end

defmodule WeightAllowances do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field:
      {:applicable_party, ["WeightAllowance", "ApplicableParty", "text()"], Downcase,
       optional?: true},
    has_many: {:weights, ["WeightAllowance", "MaximumWeight"], MaxWeight}
  )
end

defmodule BaggageAllowance do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field: {:sid, ["BaggageAllowance", "@BaggageAllowanceID"], StringType},
    field:
      {:baggage_determining_carrier_code,
       ["BaggageAllowance", "BaggageDeterminingCarrier", "AirlineID", "text()"], StringType},
    field: {:category, ["BaggageCategory", "text()"], Downcase, optional?: true},
    # This would be better as an access path, then it would be clear what is what and whether we want all or one of a thing...
    field:
      {:descriptions,
       [
         "BaggageAllowance",
         "AllowanceDescription",
         "Descriptions",
         "Description",
         "Text",
         "text()"
       ], StringType, optional?: true},
    has_one:
      {:piece_allowances, ["BaggageAllowance", "PieceAllowance"], PieceAllowance, optional?: true},
    has_many:
      {:weight_allowances, ["BaggageAllowance", "WeightAllowance"], WeightAllowance,
       optional?: true}
  )
end

defmodule CurrencyMetadata do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field: {:code, ["CurrencyMetadata", "@MetadataKey"], StringType, optional?: true},
    field: {:decimals, ["CurrencyMetadata", "Decimals", "text()"], StringType, optional?: true}
  )

  def cast(data) do
    DataSchema.to_struct(data, __MODULE__)
  end
end

defmodule FareGroup do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field: {:sid, ["FareGroup", "@ListKey"], StringType, optional?: true},
    field: {:fare_code, ["FareGroup", "Fare", "FareCode", "text()"], StringType, optional?: true},
    field:
      {:fare_basis_code, ["FareGroup", "FareBasisCode", "Code", "text()"], StringType,
       optional?: true}
  )
end

defmodule Journey do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field: {:sid, ["Flight", "@FlightKey"], &__MODULE__.trim/1, optional?: true},
    field: {:duration, ["Flight", "Journey", "Time", "text()"], BlankAsNil, optional?: true},
    field:
      {:segments, ["Flight", "SegmentReferences", "text()"], StringSplitOnSpace, optional?: true}
  )

  def split(value) do
    {:ok, String.split(value, " ")}
  end

  def trim(value) do
    {:ok, String.trim(value)}
  end
end

defmodule RuleMetadata do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field: {:metadata_key, ["RuleMetadata", "@MetadataKey"], StringType, optional?: true},
    field: {:type, ["RuleMetadata", "RuleID", "text()"], StringType, optional?: true},
    field:
      {:allowed, ["RuleMetadata", "Values", "Value", "Instruction", "text()"],
       fn x -> {:ok, x == "Allowed"} end, optional?: true}
  )

  def cast(data) do
    DataSchema.to_struct(data, __MODULE__)
  end
end

defmodule OfferBaggageAllowance do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field:
      {:baggage_allowance_sid, ["BaggageAllowance", "BaggageAllowanceRef", "text()"], StringType,
       optional?: true},
    field:
      {:journey_sids, ["BaggageAllowance", "FlightRefs", "text()"], StringSplitOnSpace,
       optional?: true},
    field:
      {:passenger_ids, ["BaggageAllowance", "PassengerRefs", "text()"], StringSplitOnSpace,
       optional?: true}
  )

  def split(value) do
    {:ok, String.split(value, " ")}
  end
end

defmodule OfferJourney do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field: {:sid, ["FlightRef", "text()"], &__MODULE__.trim/1, optional?: true},
    field: {:origin_destination_sid, ["FlightRef", "@ODRef"], StringType, optional?: true},
    field: {:price_class_sid, ["FlightRef", "@PriceClassRef"], StringType, optional?: true}
  )

  def trim(x) do
    {:ok, String.trim(x)}
  end
end

defmodule FareRuleDetail do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field: {:metadata_rule_ref, ["Detail", "@refs"], StringType, optional?: true},
    field: {:type, ["Detail", "Type", "text()"], StringType, optional?: true}
  )
end

defmodule FareRule do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    list_of:
      {:ticketing_endorsements,
       ["FareRules", "Ticketing", "Endorsements", "Endorsement", "text()"], StringType,
       optional?: true},
    field:
      {:penalty_sids, ["FareRules", "Penalty", "@refs"], StringSplitOnSpace, optional?: true},
    has_many:
      {:details, ["FareRules", "Penalty", "Details", "Detail"], FareRuleDetail, optional?: true}
  )
end

defmodule FareComponentPriceTax do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field: {:amount, ["Tax", "Amount", "text()"], DecimalType, optional?: true},
    field: {:currency, ["Tax", "Amount", "@Code"], StringType, optional?: true},
    field: {:curdescriptionrency, ["Tax", "Description", "text()"], StringType, optional?: true},
    field: {:local_amount, ["Tax", "LocalAmount", "text()"], DecimalType, optional?: true},
    field: {:local_currency, ["Tax", "LocalAmount", "@Code"], StringType, optional?: true},
    field: {:nation_code, ["Tax", "Nation", "text()"], StringType, optional?: true},
    field: {:tax_code, ["Tax", "TaxCode", "text()"], StringType, optional?: true}
  )
end

defmodule FareComponentPrice do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field: {:base_amount, ["Price", "BaseAmount", "text()"], DecimalType, optional?: true},
    field: {:base_currency, ["Price", "BaseAmount", "@Code"], StringType, optional?: true},
    field:
      {:filed_base_amount, ["Price", "FareFiledIn", "BaseAmount", "text()"], DecimalType,
       optional?: true},
    field:
      {:filed_base_currency, ["Price", "FareFiledIn", "BaseAmount", "@Code"], StringType,
       optional?: true},
    field:
      {:filed_base_nuc, ["Price", "FareFiledIn", "NUCAmount", "text()"], DecimalType,
       optional?: true},
    field:
      {:filed_exchange_rate, ["Price", "FareFiledIn", "ExchangeRate", "text()"], StringType,
       optional?: true},
    field: {:tax_amount, ["Price", "Taxes", "Total", "text()"], DecimalType, optional?: true},
    field: {:tax_currency, ["Price", "Taxes", "Total", "@Code"], StringType, optional?: true},
    has_many:
      {:taxes, ["Price", "Taxes", "Breakdown", "Tax"], FareComponentPriceTax, optional?: true}
  )
end

defmodule FareComponent do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  @cabin_type_path ["FareComponent", "FareBasis", "CabinType"]
  data_schema(
    field:
      {:booking_classes, ["FareComponent", "FareBasis", "RBD", "text()"], StringSplitOnSpace,
       optional?: true},
    field:
      {:cabin_class_codes, @cabin_type_path ++ ["CabinTypeCode", "text()"], StringSplitOnSpace,
       optional?: true},
    field:
      {:cabin_class_marketing_names, @cabin_type_path ++ ["CabinTypeName", "text()"],
       StringSplitOnSpace, optional?: true},
    field:
      {:fare_basis_code, ["FareComponent", "FareBasis", "FareBasisCode", "Code", "text()"],
       StringType, optional?: true},
    field:
      {:ticket_desig, ["FareComponent", "TicketDesig", "text()"], StringType, optional?: true},
    field:
      {:fare_basis_reference, ["FareComponent", "FareBasis", "FareBasisCode", "@refs"],
       StringType, optional?: true},
    field:
      {:fare_basis_city_pair, ["FareComponent", "FareBasis", "FareBasisCityPair", "text()"],
       StringType, optional?: true},
    field:
      {:fare_group_sids, ["FareComponent", "FareBasis", "FareBasisCode", "@refs"],
       StringSplitOnSpace, optional?: true},
    has_one: {:fare_rules, ["FareComponent", "FareRules"], FareRule, optional?: true},
    field:
      {:price_class_sid, ["FareComponent", "PriceClassRef", "text()"], StringType,
       optional?: true},
    field:
      {:segment_sids, ["FareComponent", "SegmentRefs", "text()"], StringSplitOnSpace,
       optional?: true},
    has_one: {:price, ["FareComponent", "Price"], FareComponentPrice, optional?: true}
  )
end

defmodule FareDetail do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field:
      {:fare_indicator_code, ["FareDetail", "FareIndicatorCode", "text()"], StringType,
       optional?: true},
    field:
      {:passenger_sids, ["FareDetail", "PassengerRefs", "text()"], StringSplitOnSpace,
       optional?: true},
    list_of:
      {:remarks, ["FareDetail", "Remarks", "Remark", "text()"], StringType, optional?: true},
    has_many: {:fare_components, ["FareDetail", "FareComponent"], FareComponent, optional?: true}
  )

  def split(value) do
    {:ok, String.split(value, " ")}
  end
end

defmodule OfferItemService do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field:
      {:journey_sids, ["Service", "FlightRefs", "text()"], StringSplitOnSpace, optional?: true},
    field:
      {:passenger_sids, ["Service", "PassengerRefs", "text()"], StringSplitOnSpace,
       optional?: true},
    field:
      {:segment_sids, ["Service", "ServiceDefinitionRef", "@SegmentRefs"], StringSplitOnSpace,
       optional?: true},
    field:
      {:service_definition_sid, ["Service", "ServiceDefinitionRef", "text()"], StringType,
       optional?: true},
    field: {:service_sid, ["Service", "ServiceRef", "text()"], StringType, optional?: true},
    field: {:sid, ["Service", "@ServiceID"], StringType, optional?: true}
  )
end

defmodule OfferItem do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  @total_path ["OfferItem", "TotalPriceDetail", "TotalAmount", "DetailCurrencyPrice", "Total"]
  data_schema(
    field:
      {:base_amount, ["OfferItem", "NotImplemented", "text()"], DecimalType, optional?: true},
    field:
      {:base_currency, ["OfferItem", "NotImplemented", "text()"], StringType, optional?: true},
    field: {:mandatory, ["OfferItem", "@MandatoryInd"], Boolean, optional?: true},
    field: {:sid, ["OfferItem", "@OfferItemID"], StringType, optional?: true},
    field: {:tax_amount, ["OfferItem", "NotImplemented", "text()"], DecimalType, optional?: true},
    field:
      {:tax_currency, ["OfferItem", "NotImplemented", "text()"], StringType, optional?: true},
    field: {:total_amount, @total_path ++ ["text()"], DecimalType, optional?: true},
    field: {:total_currency, @total_path ++ ["@Code"], StringType, optional?: true},
    has_many: {:fare_details, ["OfferItem", "FareDetail"], FareDetail, optional?: true},
    has_many: {:services, ["OfferItem", "Service"], OfferItemService, optional?: true}
  )
end

defmodule Offer do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  @price_guaranteed_by_path [
    "Offer",
    "TimeLimits",
    "OtherLimits",
    "OtherLimit",
    "PriceGuaranteeTimeLimit",
    "PriceGuarantee",
    "text()"
  ]
  @tax_path ["Offer", "TotalPrice", "DetailCurrencyPrice", "Taxes", "Total"]
  @ticket_by_path [
    "Offer",
    "TimeLimits",
    "OtherLimits",
    "OtherLimit",
    "TicketByTimeLimit",
    "TicketBy",
    "text()"
  ]
  @expires_at_path ["Offer", "TimeLimits", "OfferExpiration", "@DateTime"]

  data_schema(
    has_many:
      {:baggage_allowances, ["Offer", "BaggageAllowance"], OfferBaggageAllowance, optional?: true},
    field: {:base_amount, ["Offer", "NotImplemented", "text()"], StringType, optional?: true},
    field: {:base_currency, ["Offer", "NotImplemented", "text()"], StringType, optional?: true},
    has_many: {:journeys, ["Offer", "FlightsOverview", "FlightRef"], OfferJourney},
    field: {:owner_iata_code, ["Offer", "@Owner"], StringType},
    field: {:price_guaranteed_by, @price_guaranteed_by_path, StringType, optional?: true},
    field: {:sid, ["Offer", "@OfferID"], StringType},
    field: {:tax_amount, @tax_path ++ ["text()"], DecimalType, optional?: true},
    field: {:tax_currency, @tax_path ++ ["@Code"], StringType, optional?: true},
    # We need to handle adding in the point_of_sale_timezone timezone elsewhere, when we go to an link offer
    field: {:ticket_by, @ticket_by_path, StringType, optional?: true},
    # Should be DateTime.
    field: {:expires_at, @expires_at_path, StringType, optional?: true},
    field:
      {:total_amount, ["Offer", "TotalPrice", "DetailCurrencyPrice", "Total", "text()"],
       DecimalType},
    field:
      {:total_currency, ["Offer", "TotalPrice", "DetailCurrencyPrice", "Total", "@Code"],
       StringType},
    field: {:fare_type, ["Offer", "Match", "MatchResult", "text()"], StringType, optional?: true},
    has_many: {:items, ["Offer", "OfferItem"], OfferItem, optional?: true}
  )
end

defmodule OriginDestination do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field:
      {:departure_code, ["OriginDestination", "DepartureCode", "text()"], StringType,
       optional?: true},
    field:
      {:arrival_code, ["OriginDestination", "ArrivalCode", "text()"], StringType, optional?: true},
    field:
      {:journeys, ["OriginDestination", "FlightReferences", "text()"], StringSplitOnSpace,
       optional?: true},
    field: {:sid, ["OriginDestination", "@OriginDestinationKey"], StringType, optional?: true}
  )
end

defmodule Passenger do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor
  data_schema(
    field: {:sid, ["Passenger", "@PassengerID"], StringType, optional?: true},
    field:
      {:birthdate, ["Passenger", "Individual", "Birthdate", "text()"], StringType,
       optional?: true},
    field:
      {:family_name, ["Passenger", "Individual", "Surname", "text()"], StringType,
       optional?: true},
    field:
      {:gender, ["Passenger", "Individual", "Gender", "text()"], StringType, optional?: true},
    field:
      {:given_name, ["Passenger", "Individual", "GivenName", "text()"], JoinWithSpaces,
       optional?: true},
    field:
      {:title, ["Passenger", "Individual", "NameTitle", "text()"], StringType, optional?: true},
    field: {:type, ["Passenger", "PTC", "text()"], StringType, optional?: true}
  )
end

defmodule AirShop do
  import DataSchema
  @data_accessor DataSchema.SaxyStructHandlerAccessor

  @base_path [
    "SOAP-ENV:Envelope",
    "SOAP-ENV:Body",
    "ns1:XXTransactionResponse",
    "RSP",
    "AirShoppingRS"
  ]
  @currency_metadata_path @base_path ++
                            ["Metadata", "Other", "OtherMetadata", "CurrencyMetadatas"]
  @fare_group_path @base_path ++ ["DataLists", "FareList", "FareGroup"]
  @rule_metadata_path @base_path ++ ["Metadata", "Other", "OtherMetadata", "RuleMetadatas"]
  data_schema(
    field:
      {:response_sid, @base_path ++ ["ShoppingResponseID", "ResponseID", "text()"], StringType},
    has_many: {:warnings, @base_path ++ ["Warnings", "Warning"], Warning},
    has_many: {:errors, @base_path ++ ["Errors", "Error"], Error, optional?: true},
    has_many:
      {:baggage_allowances,
       @base_path ++ ["DataLists", "BaggageAllowanceList", "BaggageAllowance"], BaggageAllowance,
       optional?: true},
    list_of: {:currency_metadata, @currency_metadata_path, CurrencyMetadata, optional?: true},
    has_many: {:fare_groups, @fare_group_path, FareGroup, optional?: true},
    has_many:
      {:journeys, @base_path ++ ["DataLists", "FlightList", "Flight"], Journey, optional?: true},
    list_of: {:rule_metadata, @rule_metadata_path, RuleMetadata, optional?: true},
    has_many:
      {:offers, @base_path ++ ["OffersGroup", "AirlineOffers", "Offer"], Offer, optional?: true},
    has_many:
      {:origin_destinations,
       @base_path ++ ["DataLists", "OriginDestinationList", "OriginDestination"],
       OriginDestination, optional?: true},
    has_many:
      {:passengers, @base_path ++ ["DataLists", "PassengerList", "Passenger"], Passenger,
       optional?: true}
  )
end
