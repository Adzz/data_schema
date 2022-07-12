%{
  "SOAP-ENV:Envelope" => %{
    "SOAP-ENV:Body" => %{
      "ns1:XXTransactionResponse" => %{
        "RSP" => %{
          "AirShoppingRS" => %{
            "DataLists" => %{
              "BaggageAllowanceList" => %{
                "BaggageAllowance" =>
                  {:all,
                   %{
                     {:attr, "BaggageAllowanceID"} => true,
                     "AllowanceDescription" => %{
                       "Descriptions" => %{"Description" => %{"Text" => %{text: true}}}
                     },
                     "BaggageCategory" => %{text: true},
                     "BaggageDeterminingCarrier" => %{"AirlineID" => %{text: true}},
                     "PieceAllowance" =>
                       {:all,
                        %{
                          "ApplicableBag" => %{text: true},
                          "ApplicableParty" => %{text: true},
                          "PieceMeasurements" => %{
                            "PieceDimensionAllowance" =>
                              {:all,
                               %{
                                 "DimensionUOM" => %{text: true},
                                 "Dimensions" => %{
                                   "Category" => %{text: true},
                                   "MaxValue" => %{text: true}
                                 }
                               }},
                            "PieceWeightAllowance" =>
                              {:all,
                               %{
                                 "MaximumWeight" => %{
                                   "UOM" => %{text: true},
                                   "Value" => %{text: true}
                                 }
                               }}
                          },
                          "TotalQuantity" => %{text: true}
                        }},
                     "WeightAllowance" =>
                       {:all,
                        %{
                          "ApplicableParty" => %{text: true},
                          "MaximumWeight" =>
                            {:all, %{"UOM" => %{text: true}, "Value" => %{text: true}}}
                        }}
                   }}
              },
              "FareList" => %{
                "FareGroup" =>
                  {:all,
                   %{
                     {:attr, "ListKey"} => true,
                     "Fare" => %{"FareCode" => %{text: true}},
                     "FareBasisCode" => %{"Code" => %{text: true}}
                   }}
              },
              "FlightList" => %{
                "Flight" =>
                  {:all,
                   %{
                     {:attr, "FlightKey"} => true,
                     "Journey" => %{"Time" => %{text: true}},
                     "SegmentReferences" => %{text: true}
                   }}
              },
              "FlightSegmentList" => %{
                "FlightSegment" =>
                  {:all,
                   %{
                     {:attr, "ConnectInd"} => true,
                     {:attr, "SegmentKey"} => true,
                     "Arrival" => %{
                       "AirportCode" => %{text: true},
                       "Date" => %{text: true},
                       "Terminal" => %{"Name" => %{text: true}},
                       "Time" => %{text: true}
                     },
                     "ClassOfService" => %{
                       "Code" => %{text: true},
                       "MarketingName" => %{text: true}
                     },
                     "Departure" => %{
                       "AirportCode" => %{text: true},
                       "Date" => %{text: true},
                       "Terminal" => %{"Name" => %{text: true}},
                       "Time" => %{text: true}
                     },
                     "Equipment" => %{"AircraftCode" => %{text: true}, "Name" => %{text: true}},
                     "FlightDetail" => %{
                       "FlightDistance" => %{"UOM" => %{text: true}, "Value" => %{text: true}},
                       "FlightDuration" => %{"Value" => %{text: true}},
                       "FlightSegmentType" => %{text: true},
                       "Stops" => %{"StopQuantity" => %{text: true}}
                     },
                     "MarketingCarrier" => %{
                       "AirlineID" => %{text: true},
                       "FlightNumber" => %{text: true}
                     },
                     "OperatingCarrier" => %{
                       "AirlineID" => %{text: true},
                       "FlightNumber" => %{text: true},
                       "Name" => %{text: true}
                     }
                   }}
              },
              "OriginDestinationList" => %{
                "OriginDestination" =>
                  {:all,
                   %{
                     {:attr, "OriginDestinationKey"} => true,
                     "ArrivalCode" => %{text: true},
                     "DepartureCode" => %{text: true},
                     "FlightReferences" => %{text: true}
                   }}
              },
              "PassengerList" => %{
                "Passenger" =>
                  {:all,
                   %{
                     {:attr, "PassengerID"} => true,
                     "Individual" => %{
                       "Birthdate" => %{text: true},
                       "Gender" => %{text: true},
                       "GivenName" => {:all, %{text: true}},
                       "NameTitle" => %{text: true},
                       "Surname" => %{text: true}
                     },
                     "PTC" => %{text: true}
                   }}
              },
              "PriceClassList" => %{
                "PriceClass" =>
                  {:all,
                   %{
                     {:attr, "PriceClassID"} => true,
                     "Code" => %{text: true},
                     "Descriptions" => %{"Description" => {:all, %{"Text" => %{text: true}}}},
                     "Name" => %{text: true}
                   }}
              },
              "ServiceDefinitionList" => %{
                "ServiceDefinition" =>
                  {:all,
                   %{
                     {:attr, "Owner"} => true,
                     {:attr, "ServiceDefinitionID"} => true,
                     "BaggageAllowanceRef" => %{text: true},
                     "Descriptions" => %{"Description" => {:all, %{"Text" => %{text: true}}}},
                     "Detail" => %{
                       "ServiceItemQuantityRules" => %{
                         "MaximumQuantity" => %{text: true},
                         "MinimumQuantity" => %{text: true}
                       }
                     },
                     "Encoding" => %{"SubCode" => %{text: true}},
                     "Name" => %{text: true}
                   }}
              }
            },
            "Errors" => %{
              "Error" =>
                {:all,
                 %{
                   :text => true,
                   {:attr, "Code"} => true,
                   {:attr, "Owner"} => true,
                   {:attr, "ShortText"} => true,
                   {:attr, "Status"} => true,
                   {:attr, "Type"} => true
                 }}
            },
            "Metadata" => %{
              "Other" => %{
                "OtherMetadata" =>
                  {:all,
                   %{
                     "CurrencyMetadatas" => %{
                       "CurrencyMetadata" =>
                         {:all, %{{:attr, "MetadataKey"} => true, "Decimals" => %{text: true}}}
                     },
                     "RuleMetadatas" => %{
                       "RuleMetadata" =>
                         {:all,
                          %{
                            {:attr, "MetadataKey"} => true,
                            "RuleID" => %{text: true},
                            "Values" => %{"Value" => %{"Instruction" => %{text: true}}}
                          }}
                     }
                   }}
              },
              "Shopping" => %{
                "ShopMetadataGroup" => %{
                  "Offer" => %{
                    "OfferInstructionMetadatas" => %{
                      "OfferInstructionMetadata" =>
                        {:all,
                         %{
                           {:attr, "refs"} => true,
                           "AugmentationPoint" => %{
                             "AugPoint" => %{
                               "Combinability" => %{
                                 "Association" => %{
                                   "ReferenceValue" => {:all, %{text: true}},
                                   "Type" => %{text: true}
                                 }
                               }
                             }
                           }
                         }}
                    }
                  }
                }
              }
            },
            "OffersGroup" => %{
              "AirlineOffers" => %{
                "Offer" =>
                  {:all,
                   %{
                     {:attr, "OfferID"} => true,
                     {:attr, "Owner"} => true,
                     "BaggageAllowance" =>
                       {:all,
                        %{
                          "BaggageAllowanceRef" => %{text: true},
                          "FlightRefs" => %{text: true},
                          "PassengerRefs" => %{text: true}
                        }},
                     "FlightsOverview" => %{
                       "FlightRef" =>
                         {:all,
                          %{
                            :text => true,
                            {:attr, "ODRef"} => true,
                            {:attr, "PriceClassRef"} => true
                          }}
                     },
                     "Match" => %{"MatchResult" => %{text: true}},
                     "OfferItem" =>
                       {:all,
                        %{
                          {:attr, "MandatoryInd"} => true,
                          {:attr, "OfferItemID"} => true,
                          "FareDetail" =>
                            {:all,
                             %{
                               "FareComponent" =>
                                 {:all,
                                  %{
                                    "FareBasis" => %{
                                      "CabinType" => %{
                                        "CabinTypeCode" => %{text: true},
                                        "CabinTypeName" => %{text: true}
                                      },
                                      "FareBasisCityPair" => %{text: true},
                                      "FareBasisCode" => %{
                                        {:attr, "refs"} => true,
                                        "Code" => %{text: true}
                                      },
                                      "RBD" => %{text: true}
                                    },
                                    "FareRules" => %{
                                      "Penalty" => %{
                                        {:attr, "CancelFeeInd"} => true,
                                        {:attr, "ChangeFeeInd"} => true,
                                        "Details" => %{
                                          "Detail" =>
                                            {:all,
                                             %{
                                               {:attr, "refs"} => true,
                                               "Amounts" => %{
                                                 "Amount" =>
                                                   {:all,
                                                    %{
                                                      "AmountApplication" => %{text: true},
                                                      "CurrencyAmountValue" => %{
                                                        :text => true,
                                                        {:attr, "Code"} => true
                                                      }
                                                    }}
                                               },
                                               "Application" => %{text: true},
                                               "Type" => %{text: true}
                                             }}
                                        }
                                      },
                                      "Ticketing" => %{
                                        "Endorsements" => %{
                                          "Endorsement" => {:all, %{text: true}}
                                        }
                                      }
                                    },
                                    "Price" => %{
                                      "BaseAmount" => %{:text => true, {:attr, "Code"} => true},
                                      "FareFiledIn" => %{
                                        "BaseAmount" => %{:text => true, {:attr, "Code"} => true},
                                        "ExchangeRate" => %{text: true},
                                        "NUC_Amount" => %{text: true}
                                      },
                                      "Taxes" => %{
                                        "Breakdown" => %{
                                          "Tax" =>
                                            {:all,
                                             %{
                                               "Amount" => %{
                                                 :text => true,
                                                 {:attr, "Code"} => true
                                               },
                                               "Description" => %{text: true},
                                               "LocalAmount" => %{
                                                 :text => true,
                                                 {:attr, "Code"} => true
                                               },
                                               "Nation" => %{text: true},
                                               "TaxCode" => %{text: true}
                                             }}
                                        },
                                        "Total" => %{:text => true, {:attr, "Code"} => true}
                                      }
                                    },
                                    "PriceClassRef" => %{text: true},
                                    "SegmentRefs" => %{text: true},
                                    "TicketDesig" => %{text: true}
                                  }},
                               "FareIndicatorCode" => %{text: true},
                               "PassengerRefs" => %{text: true},
                               "Price" => %{
                                 "BaseAmount" => %{:text => true, {:attr, "Code"} => true},
                                 "FareFiledIn" => %{
                                   "BaseAmount" => %{:text => true, {:attr, "Code"} => true},
                                   "ExchangeRate" => %{text: true},
                                   "NUC_Amount" => %{text: true}
                                 },
                                 "Taxes" => %{
                                   "Breakdown" => %{
                                     "Tax" =>
                                       {:all,
                                        %{
                                          "Amount" => %{:text => true, {:attr, "Code"} => true},
                                          "Description" => %{text: true},
                                          "LocalAmount" => %{
                                            :text => true,
                                            {:attr, "Code"} => true
                                          },
                                          "Nation" => %{text: true},
                                          "TaxCode" => %{text: true}
                                        }}
                                   },
                                   "Total" => %{:text => true, {:attr, "Code"} => true}
                                 }
                               },
                               "Remarks" => %{"Remark" => {:all, %{text: true}}}
                             }},
                          "Service" =>
                            {:all,
                             %{
                               {:attr, "ServiceID"} => true,
                               "FlightRefs" => %{text: true},
                               "PassengerRefs" => %{text: true},
                               "ServiceDefinitionRef" => %{
                                 :text => true,
                                 {:attr, "SegmentRefs"} => true
                               },
                               "ServiceRef" => %{text: true}
                             }},
                          "TotalPriceDetail" => %{
                            "TotalAmount" => %{
                              "DetailCurrencyPrice" => %{
                                "Total" => %{:text => true, {:attr, "Code"} => true}
                              }
                            }
                          }
                        }},
                     "TimeLimits" => %{
                       "OfferExpiration" => %{{:attr, "DateTime"} => true},
                       "OtherLimits" => %{
                         "OtherLimit" => %{
                           "PriceGuaranteeTimeLimit" => %{"PriceGuarantee" => %{text: true}},
                           "TicketByTimeLimit" => %{"TicketBy" => %{text: true}}
                         }
                       }
                     },
                     "TotalPrice" => %{
                       "DetailCurrencyPrice" => %{
                         "Taxes" => %{"Total" => %{:text => true, {:attr, "Code"} => true}},
                         "Total" => %{:text => true, {:attr, "Code"} => true}
                       }
                     }
                   }}
              }
            },
            "ShoppingResponseID" => %{"ResponseID" => %{text: true}},
            "Warnings" => %{
              "Warning" =>
                {:all,
                 %{
                   :text => true,
                   {:attr, "Code"} => true,
                   {:attr, "Owner"} => true,
                   {:attr, "ShortText"} => true,
                   {:attr, "Type"} => true
                 }}
            }
          }
        }
      }
    }
  }
}
