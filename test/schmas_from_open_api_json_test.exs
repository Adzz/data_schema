defmodule DataSchema.SchmasFromOpenApiJsonTest do
  use ExUnit.Case, async: true

  test "get with object" do
    json = ~S({
      "paths": {
        "/air/aircraft/{id}": {
          "get": {
            "operationId": "getAircraftById",
            "responses": {
              "200": {
                "content": {
                  "application/json": {
                    "schema": {
                      "type": "object",
                      "properties": {
                        "data": {
                          "title": "Aircraft",
                          "type": "object",
                          "properties": {
                            "iata_code": {
                              "type": "string",
                              "example": "380"
                            },
                            "id": {
                              "type": "string",
                              "example": "arc_00009UhD4ongolulWd91Ky"
                            },
                            "name": {
                              "type": "string",
                              "example": "Airbus Industries A380"
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    })

    assert DataSchema.OpenApi.schemas_from_open_api_json(json) == %{
             "GET GetAircraftById" => [
               has_one:
                 {:data, "data",
                  [
                    field: {:name, "name", "string"},
                    field: {:id, "id", "string"},
                    field: {:iata_code, "iata_code", "string"}
                  ]}
             ]
           }
  end

  test "properties with list of things." do
    json = ~S({
      "paths": {
        "/air/aircraft": {
          "get": {
            "operationId": "getAircraft",
            "responses": {
              "200": {
                "content": {
                  "application/json": {
                    "schema": {
                      "type": "object",
                      "properties": {
                        "data": {
                          "type": "array",
                          "items": {
                            "title": "Aircraft",
                            "type": "object",
                            "properties": {
                              "iata_code": {
                                "type": "string",
                                "example": "380"
                              },
                              "id": {
                                "type": "string",
                                "example": "arc_00009UhD4ongolulWd91Ky"
                              },
                              "name": {
                                "type": "string",
                                "example": "Airbus Industries A380"
                              }
                            }
                          }
                        },
                        "meta": {
                          "title": "Pagination Meta",
                          "type": "object",
                          "properties": {
                            "after": {
                              "type": "string",
                              "nullable": true,
                              "example": "g2wAAAACbQAAABBBZXJvbWlzdC1LaGFya2l2bQAAAB="
                            },
                            "before": {
                              "type": "string",
                              "nullable": true,
                              "example": null
                            },
                            "limit": {
                              "type": "integer",
                              "default": 50,
                              "minimum": 1,
                              "maximum": 200,
                              "nullable": true,
                              "example": 50
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    })

    # This essentially returns an IR that we can then use to create actual modules by writing to files
    # with config. For example, we can have a map of operationId to module file or whatever
    # which would tell us where to put things. And we could have a map for each type in the
    # open API schema to a casting fn.
    assert DataSchema.OpenApi.schemas_from_open_api_json(json) == %{
             "GET GetAircraft" => [
               has_one:
                 {:meta, "meta",
                  [
                    field: {:limit, "limit", "integer"},
                    field: {:before, "before", "string"},
                    field: {:after, "after", "string"},
                    has_many: {:data, "data", [field: {:name, "name"}]}
                  ]},
               has_many: {:data, "data", [field: {:name, "name"}]}
             ]
           }
  end

  describe "post" do
    test "we can determine the correct shape of data from a post" do
      json = ~S({
        "paths": {
          "/air/offer_requests": {
            "post": {
              "summary": "Create an offer request",
              "operationId": "createOfferRequest",
              "requestBody": {
                "content": {
                  "application/json": {
                    "schema": {
                      "type": "object",
                      "required": [
                        "data"
                      ],
                      "properties": {
                        "data": {
                          "title": "Offer Request Body",
                          "type": "object",
                          "required": [
                            "slices",
                            "passengers"
                          ],
                          "properties": {
                            "cabin_class": {
                              "description": "The cabin that the passengers want to travel in",
                              "type": "string",
                              "enum": [
                                "first",
                                "business",
                                "premium_economy",
                                "economy"
                              ],
                              "example": "economy"
                            },
                            "slices": {
                              "description": "The [slices](/docs/api/overview/key-principles\) that make up this offer request. One-way journeys can be expressed using one slice, whereas return trips will need two.",
                              "type": "array",
                              "items": {
                                "type": "object",
                                "title": "Offer Request Body Slice",
                                "required": [
                                  "departure_date",
                                  "destination",
                                  "origin"
                                ],
                                "properties": {
                                  "departure_date": {
                                    "type": "string",
                                    "format": "date",
                                    "description": "The [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601\) date on which the passengers want to depart",
                                    "example": "2020-04-24"
                                  },
                                  "destination": {
                                    "description": "The 3-letter IATA code for the city or airport where this slice ends",
                                    "type": "string",
                                    "example": "JFK"
                                  },
                                  "origin": {
                                    "description": "The 3-letter IATA code for the city or airport where this slice starts",
                                    "type": "string",
                                    "example": "LHR"
                                  }
                                }
                              }
                            },
                            "passengers": {
                              "description": "The passengers who want to travel. If you specify an `age` for a passenger, the `type` may differ for the same passenger in different offers due to airline's different rules. e.g. one airline may treat a 14 year old as an adult, and another as a young adult. You may only specify an `age` or a `type` – not both.",
                              "type": "array",
                              "items": {
                                "oneOf": [
                                  {
                                    "type": "object",
                                    "title": "Offer Request Body Passenger With Type",
                                    "description": "A passenger specified by their type",
                                    "required": [
                                      "type"
                                    ],
                                    "properties": {
                                      "type": {
                                        "type": "string",
                                        "description": "The type of the passenger. If the passenger is aged 18 or over, you should specify a `type` of `adult`. If a passenger is aged under 18, you should specify their `age` instead of a `type`. A passenger can have only a type or an age, but not both.",
                                        "enum": [
                                          "adult",
                                          "child",
                                          "infant_without_seat"
                                        ],
                                        "example": "adult"
                                      },
                                      "given_name": {
                                        "type": "string",
                                        "description": "The passenger's given name. Only `space`, `-`, `'`, and letters from the [`ASCII`](https://www.unicode.org/charts/PDF/U0000.pdf\), [`Latin-1 Supplement`](https://www.unicode.org/charts/PDF/U0080.pdf\) and [`Latin Extended-A`](https://www.unicode.org/charts/PDF/U0100.pdf\) (with the exceptions of `Æ`, `æ`, `Ĳ`, `ĳ`, `Œ`, `œ`, `Þ`, and `ð`\) Unicode charts are accepted. All other characters will result in a validation error. The minimum length is 1 character, and the maximum is 20 characters.\n\nThis is only required if you're also including __Loyalty Programme Accounts__.\n",
                                        "example": "Amelia"
                                      },
                                      "family_name": {
                                        "type": "string",
                                        "description": "The passenger's family name. Only `space`, `-`, `'`, and letters from the [`ASCII`](https://www.unicode.org/charts/PDF/U0000.pdf\), [`Latin-1 Supplement`](https://www.unicode.org/charts/PDF/U0080.pdf\) and [`Latin Extended-A`](https://www.unicode.org/charts/PDF/U0100.pdf\) (with the exceptions of `Æ`, `æ`, `Ĳ`, `ĳ`, `Œ`, `œ`, `Þ`, and `ð`\) Unicode charts are accepted. All other characters will result in a validation error. The minimum length is 1 character, and the maximum is 20 characters.\n\nThis is only required if you're also including __Loyalty Programme Accounts__.\n",
                                        "example": "Earhart"
                                      },
                                      "loyalty_programme_accounts": {
                                        "type": "array",
                                        "description": "The __Loyalty Programme Accounts__ for this passenger",
                                        "items": {
                                          "type": "object",
                                          "title": "Loyalty Programme Account",
                                          "properties": {
                                            "airline_iata_code": {
                                              "type": "string",
                                              "description": "The IATA code for the airline that this __Loyalty Programme Account__ belongs to",
                                              "example": "BA"
                                            },
                                            "account_number": {
                                              "type": "string",
                                              "description": "The passenger's account number for this __Loyalty Programme Account__",
                                              "example": "12901014"
                                            }
                                          }
                                        }
                                      }
                                    }
                                  },
                                  {
                                    "type": "object",
                                    "title": "Offer Request Body Passenger With Age",
                                    "description": "A passenger specified by their age",
                                    "required": [
                                      "age"
                                    ],
                                    "properties": {
                                      "age": {
                                        "type": "integer",
                                        "description": "The age of the passenger on the `departure_date` of the final slice. e.g. if you a searching for a round trip and the passenger is 15 years old at the time of the outbound flight, but they then have their birthday and are 16 years old for the inbound flight, you must set the age to 16. You should specify an `age` for passengers who are under 18 years old. A passenger can have only a type or an age, but not both.",
                                        "example": 14,
                                        "minimum": 0,
                                        "maximum": 130
                                      },
                                      "given_name": {
                                        "type": "string",
                                        "description": "The passenger's given name. Only `space`, `-`, `'`, and letters from the [`ASCII`](https://www.unicode.org/charts/PDF/U0000.pdf\), [`Latin-1 Supplement`](https://www.unicode.org/charts/PDF/U0080.pdf\) and [`Latin Extended-A`](https://www.unicode.org/charts/PDF/U0100.pdf\) (with the exceptions of `Æ`, `æ`, `Ĳ`, `ĳ`, `Œ`, `œ`, `Þ`, and `ð`\) Unicode charts are accepted. All other characters will result in a validation error. The minimum length is 1 character, and the maximum is 20 characters.\n\nThis is only required if you're also including __Loyalty Programme Accounts__.\n",
                                        "example": "Amelia"
                                      },
                                      "family_name": {
                                        "type": "string",
                                        "description": "The passenger's family name. Only `space`, `-`, `'`, and letters from the [`ASCII`](https://www.unicode.org/charts/PDF/U0000.pdf\), [`Latin-1 Supplement`](https://www.unicode.org/charts/PDF/U0080.pdf\) and [`Latin Extended-A`](https://www.unicode.org/charts/PDF/U0100.pdf\) (with the exceptions of `Æ`, `æ`, `Ĳ`, `ĳ`, `Œ`, `œ`, `Þ`, and `ð`\) Unicode charts are accepted. All other characters will result in a validation error. The minimum length is 1 character, and the maximum is 20 characters.\n\nThis is only required if you're also including __Loyalty Programme Accounts__.\n",
                                        "example": "Earhart"
                                      },
                                      "loyalty_programme_accounts": {
                                        "type": "array",
                                        "description": "The __Loyalty Programme Accounts__ for this passenger",
                                        "items": {
                                          "type": "object",
                                          "title": "Loyalty Programme Account",
                                          "properties": {
                                            "airline_iata_code": {
                                              "type": "string",
                                              "description": "The IATA code for the airline that this __Loyalty Programme Account__ belongs to",
                                              "example": "BA"
                                            },
                                            "account_number": {
                                              "type": "string",
                                              "description": "The passenger's account number for this __Loyalty Programme Account__",
                                              "example": "12901014"
                                            }
                                          }
                                        }
                                      }
                                    }
                                  }
                                ]
                              },
                              "example": [
                                {
                                  "type": "adult",
                                  "given_name": "Amelia",
                                  "family_name": "Earhart",
                                  "loyalty_programme_accounts": [
                                    {
                                      "airline_iata_code": "BA",
                                      "account_number": "12901014"
                                    }
                                  ]
                                },
                                {
                                  "age": 14
                                }
                              ]
                            },
                            "requested_sources": {
                              "x-private": true,
                              "description": "The sources to send your offer request to, in order to ask for offers",
                              "type": "array",
                              "example": [
                                "american_airlines",
                                "british_airways"
                              ],
                              "items": {
                                "type": "string",
                                "example": "american_airlines"
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              },
              "responses": {
                "200": {
                  "description": "An offer request",
                  "content": {
                    "application/json": {
                      "schema": {
                        "type": "object",
                        "properties": {
                          "data": {
                            "type": "object",
                            "title": "Offer Request",
                            "properties": {
                              "cabin_class": {
                                "description": "The cabin that the passengers want to travel in",
                                "type": "string",
                                "enum": [
                                  "first",
                                  "business",
                                  "premium_economy",
                                  "economy"
                                ],
                                "example": "economy"
                              },
                              "id": {
                                "description": "Duffel's unique identifier for the offer request",
                                "type": "string",
                                "example": "orq_00009hjdomFOCJyxHG7k7k"
                              },
                              "created_at": {
                                "description": "The [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601\) datetime at which the offer request was created",
                                "type": "string",
                                "format": "date-time",
                                "example": "2020-02-12T15:21:01.927Z"
                              },
                              "live_mode": {
                                "description": "Whether the offer request was created in live mode. This field will be set to `true` if the offer request was created in live mode, or `false` if it was created in test mode.",
                                "type": "boolean",
                                "example": false
                              },
                              "offers": {
                                "description": "The offers returned by the airlines",
                                "type": "array",
                                "items": {
                                  "type": "object",
                                  "title": "Offer Index",
                                  "properties": {
                                    "allowed_passenger_identity_document_types": {
                                      "description": "The types of identity documents that may be provided for the passengers when creating an order based on this offer. Currently, the only supported type is `passport`. If this is `[]`, then you must not provide identity documents.",
                                      "type": "array",
                                      "items": {
                                        "type": "string",
                                        "enum": [
                                          "passport"
                                        ]
                                      },
                                      "example": [
                                        "passport"
                                      ]
                                    },
                                    "base_amount": {
                                      "description": "The base price of the offer for all passengers, excluding taxes. It does not include the base amount of any service(s\) that might be booked with the offer.",
                                      "type": "string",
                                      "example": "30.20"
                                    },
                                    "base_currency": {
                                      "description": "The currency of the `base_amount`, as an [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217\) currency code.\nIt will match your organisation's billing currency unless you’re using Duffel as an accredited IATA agent, in which case it will be in the currency provided by the airline (which will usually be based on the country where your IATA agency is registered\).\n",
                                      "example": "GBP",
                                      "format": "ISO 4217",
                                      "type": "string"
                                    },
                                    "conditions": {
                                      "type": "object",
                                      "title": "OfferConditions",
                                      "description": "The conditions associated with this offer, describing the kinds of modifications you can make post-booking and any penalties that will apply to those modifications.\nThis information assumes the condition is applied to all of the slices and passengers associated with this offer - for information at the slice level (e.g. \"what happens if I just want to change the first slice?\"\) refer to the `slices`.\nIf a particular kind of modification is allowed, you may not always be able to take action through the Duffel API. In some cases, you may need to contact the Duffel support team or the airline directly.\n",
                                      "properties": {
                                        "change_before_departure": {
                                          "type": "object",
                                          "nullable": true,
                                          "description": "Whether the whole offer can be changed before the departure of the first slice.\nIf all of the slices on the offer can be changed then the `allowed` property will be `true`. Refer to the `slices` for information about change penalties.\nIf any of the slices on the offer can't be changed then the `allowed` property will be `false`. In this case you should refer to the `slices` conditions to determine if any part of the offer is changeable.\nIf the airline hasn't provided any information about whether this offer can be changed then this property will be `null`.\n",
                                          "properties": {
                                            "allowed": {
                                              "description": "Whether this kind of modification is allowed post-booking",
                                              "nullable": false,
                                              "type": "boolean",
                                              "example": true
                                            },
                                            "penalty_amount": {
                                              "description": "If the modification is `allowed` then this is the amount payable to apply the modification to all passengers. If there is no penalty, the value will be zero.\nIf the modification isn't `allowed` or the penalty is not known then this field will be `null`.\nIf this is `null` then the `penalty_currency` will also be `null`.\n",
                                              "nullable": true,
                                              "type": "string",
                                              "example": "100.00"
                                            },
                                            "penalty_currency": {
                                              "description": "The currency of the `penalty_amount` as an [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217\) currency code.\nThis will be in a currency determined by the airline, which is not necessarily the same as the currency of the offer or order.\nIf this is `null` then `penalty_amount` will also be `null`.\n",
                                              "example": "GBP",
                                              "format": "ISO 4217",
                                              "nullable": true,
                                              "type": "string"
                                            }
                                          }
                                        },
                                        "refund_before_departure": {
                                          "type": "object",
                                          "nullable": true,
                                          "description": "Whether the whole offer can be refunded before the departure of the first slice.\nIf all of the slices on the offer can be refunded then the `allowed` property will be `true` and information will be provided about any penalties.\nIf any of the slices on the offer can't be refunded then the `allowed` property will be `false`.\nIf the airline hasn't provided any information about whether this offer can be refunded then this property will be `null`.\n",
                                          "properties": {
                                            "allowed": {
                                              "description": "Whether this kind of modification is allowed post-booking",
                                              "nullable": false,
                                              "type": "boolean",
                                              "example": true
                                            },
                                            "penalty_amount": {
                                              "description": "If the modification is `allowed` then this is the amount payable to apply the modification to all passengers. If there is no penalty, the value will be zero.\nIf the modification isn't `allowed` or the penalty is not known then this field will be `null`.\nIf this is `null` then the `penalty_currency` will also be `null`.\n",
                                              "nullable": true,
                                              "type": "string",
                                              "example": "100.00"
                                            },
                                            "penalty_currency": {
                                              "description": "The currency of the `penalty_amount` as an [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217\) currency code.\nThis will be in a currency determined by the airline, which is not necessarily the same as the currency of the offer or order.\nIf this is `null` then `penalty_amount` will also be `null`.\n",
                                              "example": "GBP",
                                              "format": "ISO 4217",
                                              "nullable": true,
                                              "type": "string"
                                            }
                                          }
                                        }
                                      }
                                    },
                                    "created_at": {
                                      "description": "The [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601\) datetime at which the offer was created",
                                      "type": "string",
                                      "format": "date-time",
                                      "example": "2020-01-17T10:12:14.545Z"
                                    },
                                    "expires_at": {
                                      "description": "The [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601\) datetime at which the offer will expire and no longer be usable to create an order",
                                      "type": "string",
                                      "format": "date-time",
                                      "example": "2020-01-17T10:42:14.545Z"
                                    },
                                    "id": {
                                      "description": "Duffel's unique identifier for the offer",
                                      "type": "string",
                                      "example": "off_00009htYpSCXrwaB9DnUm0"
                                    },
                                    "live_mode": {
                                      "description": "Whether the offer request was created in live mode. This field will be set to `true` if the offer request was created in live mode, or `false` if it was created in test mode.",
                                      "type": "boolean",
                                      "example": true
                                    },
                                    "owner": {
                                      "allOf": [
                                        {
                                          "title": "Airline",
                                          "type": "object",
                                          "properties": {
                                            "iata_code": {
                                              "type": "string",
                                              "nullable": true,
                                              "description": "The two-character IATA code for the airline. This may be `null` for non-IATA carriers.",
                                              "example": "BA"
                                            },
                                            "id": {
                                              "type": "string",
                                              "description": "Duffel's unique identifier for the airline",
                                              "example": "aln_00001876aqC8c5umZmrRds"
                                            },
                                            "name": {
                                              "type": "string",
                                              "description": "The name of the airline",
                                              "example": "British Airways"
                                            }
                                          }
                                        },
                                        {
                                          "description": "The airline which provided the offer"
                                        }
                                      ]
                                    },
                                    "passenger_identity_documents_required": {
                                      "description": "Whether identity documents must be provided for each of the passengers when creating an order based on this offer. If this is `true`, you must provide an identity document for every passenger.",
                                      "type": "boolean",
                                      "example": false
                                    },
                                    "passengers": {
                                      "type": "array",
                                      "description": "The passengers included in the offer",
                                      "items": {
                                        "type": "object",
                                        "title": "Offer Passenger",
                                        "properties": {
                                          "age": {
                                            "type": "integer",
                                            "description": "The age of the passenger on the `departure_date` of the final slice",
                                            "example": 14,
                                            "minimum": 0,
                                            "maximum": 130
                                          },
                                          "type": {
                                            "type": "string",
                                            "description": "The type of the passenger",
                                            "enum": [
                                              "adult",
                                              "child",
                                              "infant_without_seat"
                                            ],
                                            "example": "adult"
                                          },
                                          "id": {
                                            "type": "string",
                                            "description": "The identifier for the passenger. This ID will be generated by Duffel",
                                            "example": "pas_00009hj8USM7Ncg31cBCL"
                                          },
                                          "given_name": {
                                            "type": "string",
                                            "nullable": true,
                                            "description": "The passenger's given name. Only `space`, `-`, `'`, and letters from the [`ASCII`](https://www.unicode.org/charts/PDF/U0000.pdf\), [`Latin-1 Supplement`](https://www.unicode.org/charts/PDF/U0080.pdf\) and [`Latin Extended-A`](https://www.unicode.org/charts/PDF/U0100.pdf\) (with the exceptions of `Æ`, `æ`, `Ĳ`, `ĳ`, `Œ`, `œ`, `Þ`, and `ð`\) Unicode charts are accepted. All other characters will result in a validation error. The minimum length is 1 character, and the maximum is 20 characters.\n\nThis is only required if you're also including __Loyalty Programme Accounts__.\n",
                                            "example": "Amelia"
                                          },
                                          "family_name": {
                                            "nullable": true,
                                            "type": "string",
                                            "description": "The passenger's family name. Only `space`, `-`, `'`, and letters from the [`ASCII`](https://www.unicode.org/charts/PDF/U0000.pdf\), [`Latin-1 Supplement`](https://www.unicode.org/charts/PDF/U0080.pdf\) and [`Latin Extended-A`](https://www.unicode.org/charts/PDF/U0100.pdf\) (with the exceptions of `Æ`, `æ`, `Ĳ`, `ĳ`, `Œ`, `œ`, `Þ`, and `ð`\) Unicode charts are accepted. All other characters will result in a validation error. The minimum length is 1 character, and the maximum is 20 characters.\n\nThis is only required if you're also including __Loyalty Programme Accounts__.\n",
                                            "example": "Earhart"
                                          },
                                          "loyalty_programme_accounts": {
                                            "type": "array",
                                            "description": "The __Loyalty Programme Accounts__ for this passenger",
                                            "items": {
                                              "type": "object",
                                              "title": "Loyalty Programme Account",
                                              "properties": {
                                                "airline_iata_code": {
                                                  "type": "string",
                                                  "description": "The IATA code for the airline that this __Loyalty Programme Account__ belongs to",
                                                  "example": "BA"
                                                },
                                                "account_number": {
                                                  "type": "string",
                                                  "description": "The passenger's account number for this __Loyalty Programme Account__",
                                                  "example": "12901014"
                                                }
                                              }
                                            }
                                          }
                                        }
                                      }
                                    },
                                    "payment_requirements": {
                                      "allOf": [
                                        {
                                          "type": "object",
                                          "title": "OfferPaymentRequirements",
                                          "properties": {
                                            "payment_required_by": {
                                              "type": "string",
                                              "nullable": true,
                                              "format": "date-time",
                                              "description": "The [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601\) datetime by which you must pay for this offer. At this time, if still unpaid, the reserved space on the flight(s\) will be released and you will have to create a new order.\nThis will be `null` when the offer requires immediate payment - that is, when `requires_instant_payment` is `true`.\n",
                                              "example": "2020-01-17T10:42:14Z"
                                            },
                                            "price_guarantee_expires_at": {
                                              "type": "string",
                                              "nullable": true,
                                              "format": "date-time",
                                              "description": "The [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601\) datetime at which the price associated with the order will no longer be guaranteed by the airline and may change before payment.\nThis will be `null` when `requires_instant_payment` is `true`.\n",
                                              "example": "2020-01-17T10:42:14"
                                            },
                                            "requires_instant_payment": {
                                              "type": "boolean",
                                              "description": "When payment is required at the time of booking this will be `true` and `payment_required_by` and `price_guarantee_expires_at` will be `null`. When payment can be made at a time after booking, this will be `false` and the time limits on the payment will be provided in `payment_required_by` and `price_guarantee_expires_at`.\n",
                                              "example": false
                                            }
                                          }
                                        },
                                        {
                                          "description": "The payment requirements for this offer"
                                        }
                                      ]
                                    },
                                    "slices": {
                                      "type": "array",
                                      "description": "The [slices](/docs/api/overview/key-principles\) that make up this offer. Each slice will include one or more [segments](/docs/api/overview/key-principles\), the specific flights that the airline is offering to take the passengers from the slice's `origin` to its `destination`.",
                                      "items": {
                                        "title": "Offer Slice",
                                        "type": "object",
                                        "properties": {
                                          "destination_type": {
                                            "type": "string",
                                            "description": "The type of the destination",
                                            "enum": [
                                              "airport",
                                              "city"
                                            ],
                                            "example": "airport"
                                          },
                                          "destination": {
                                            "allOf": [
                                              {
                                                "title": "Place",
                                                "type": "object",
                                                "properties": {
                                                  "iata_city_code": {
                                                    "type": "string",
                                                    "description": "The 3-letter IATA code for the city where the place is located. Only present for airports which are registered with IATA as belonging to a [metropolitan area](https://portal.iata.org/faq/articles/en_US/FAQ/How-do-I-create-a-new-Metropolitan-Area\).",
                                                    "example": "NYC",
                                                    "nullable": true
                                                  },
                                                  "iata_code": {
                                                    "description": "The 3-letter IATA code for the place",
                                                    "type": "string",
                                                    "example": "JFK"
                                                  },
                                                  "id": {
                                                    "type": "string",
                                                    "description": "Duffel's unique identifier for the place",
                                                    "example": "arp_jfk_us"
                                                  },
                                                  "name": {
                                                    "type": "string",
                                                    "description": "The name of the place",
                                                    "example": "John F. Kennedy International Airport"
                                                  },
                                                  "type": {
                                                    "type": "string",
                                                    "enum": [
                                                      "airport",
                                                      "city"
                                                    ],
                                                    "description": "The type of the place",
                                                    "example": "airport"
                                                  },
                                                  "iata_country_code": {
                                                    "type": "string",
                                                    "format": "ISO 3166-1 alpha-2",
                                                    "description": "The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\) code for the country where the city is located",
                                                    "example": "US"
                                                  },
                                                  "latitude": {
                                                    "type": "number",
                                                    "format": "float",
                                                    "description": "The latitude position of the airport represented in [Decimal degrees](https://en.wikipedia.org/wiki/Decimal_degrees\) with 6 decimal points with a range between -90° and 90°",
                                                    "example": 40.640556,
                                                    "nullable": true
                                                  },
                                                  "longitude": {
                                                    "type": "number",
                                                    "format": "float",
                                                    "description": "The longitude position of the airport represented in [Decimal degrees](https://en.wikipedia.org/wiki/Decimal_degrees\) with 6 decimal points with a range between -180° and 180°",
                                                    "example": -73.778519,
                                                    "nullable": true
                                                  },
                                                  "icao_code": {
                                                    "type": "string",
                                                    "description": "The four-character ICAO code for the airport",
                                                    "example": "KJFK",
                                                    "nullable": true
                                                  },
                                                  "time_zone": {
                                                    "type": "string",
                                                    "description": "The time zone of the airport, specified by name from the [tz database](https://en.wikipedia.org/wiki/Tz_database\)",
                                                    "example": "America/New_York",
                                                    "nullable": true
                                                  },
                                                  "city_name": {
                                                    "type": "string",
                                                    "description": "The name of the city (or cities separated by a `/`\) where the airport is located",
                                                    "example": "New York",
                                                    "nullable": true
                                                  },
                                                  "city": {
                                                    "allOf": [
                                                      {
                                                        "title": "City",
                                                        "type": "object",
                                                        "description": "The metropolitan area where the airport is located. Only present for airports which are registered with IATA as belonging to a [metropolitan area](https://portal.iata.org/faq/articles/en_US/FAQ/How-do-I-create-a-new-Metropolitan-Area\).",
                                                        "properties": {
                                                          "iata_code": {
                                                            "type": "string",
                                                            "description": "The three-character IATA code for the city",
                                                            "example": "NYC"
                                                          },
                                                          "id": {
                                                            "type": "string",
                                                            "description": "Duffel's unique identifier for the city",
                                                            "example": "cit_nyc_us"
                                                          },
                                                          "name": {
                                                            "type": "string",
                                                            "description": "The name of the city",
                                                            "example": "New York"
                                                          },
                                                          "iata_country_code": {
                                                            "type": "string",
                                                            "format": "ISO 3166-1 alpha-2",
                                                            "description": "The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\) code for the country where the city is located",
                                                            "example": "US"
                                                          }
                                                        }
                                                      },
                                                      {
                                                        "nullable": true
                                                      }
                                                    ]
                                                  },
                                                  "airports": {
                                                    "type": "array",
                                                    "description": "The airports associated to a city. This will only be provided where the `type` is `city`.",
                                                    "nullable": true,
                                                    "items": {
                                                      "title": "Airport",
                                                      "type": "object",
                                                      "properties": {
                                                        "iata_code": {
                                                          "type": "string",
                                                          "nullable": true,
                                                          "description": "The three-character IATA code for the airport",
                                                          "example": "JFK"
                                                        },
                                                        "id": {
                                                          "type": "string",
                                                          "description": "Duffel's unique identifier for the airport",
                                                          "example": "arp_jfk_us"
                                                        },
                                                        "name": {
                                                          "type": "string",
                                                          "description": "The name of the airport",
                                                          "example": "John F. Kennedy International Airport"
                                                        },
                                                        "iata_country_code": {
                                                          "type": "string",
                                                          "format": "ISO 3166-1 alpha-2",
                                                          "description": "The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\) code for the country where the airport is located",
                                                          "example": "US"
                                                        },
                                                        "latitude": {
                                                          "type": "number",
                                                          "format": "float",
                                                          "description": "The latitude position of the airport represented in [Decimal degrees](https://en.wikipedia.org/wiki/Decimal_degrees\) with 6 decimal points with a range between -90° and 90°",
                                                          "example": 40.640556
                                                        },
                                                        "longitude": {
                                                          "type": "number",
                                                          "format": "float",
                                                          "description": "The longitude position of the airport represented in [Decimal degrees](https://en.wikipedia.org/wiki/Decimal_degrees\) with 6 decimal points with a range between -180° and 180°",
                                                          "example": -73.778519
                                                        },
                                                        "icao_code": {
                                                          "type": "string",
                                                          "nullable": true,
                                                          "description": "The four-character ICAO code for the airport",
                                                          "example": "KJFK"
                                                        },
                                                        "time_zone": {
                                                          "type": "string",
                                                          "description": "The time zone of the airport, specified by name from the [tz database](https://en.wikipedia.org/wiki/Tz_database\)",
                                                          "example": "America/New_York"
                                                        },
                                                        "city_name": {
                                                          "type": "string",
                                                          "description": "The name of the city (or cities separated by a `/`\) where the airport is located",
                                                          "example": "New York"
                                                        },
                                                        "city": {
                                                          "nullable": true,
                                                          "title": "City",
                                                          "type": "object",
                                                          "description": "The metropolitan area where the airport is located. Only present for airports which are registered with IATA as belonging to a [metropolitan area](https://portal.iata.org/faq/articles/en_US/FAQ/How-do-I-create-a-new-Metropolitan-Area\).",
                                                          "properties": {
                                                            "iata_code": {
                                                              "type": "string",
                                                              "description": "The three-character IATA code for the city",
                                                              "example": "NYC"
                                                            },
                                                            "id": {
                                                              "type": "string",
                                                              "description": "Duffel's unique identifier for the city",
                                                              "example": "cit_nyc_us"
                                                            },
                                                            "name": {
                                                              "type": "string",
                                                              "description": "The name of the city",
                                                              "example": "New York"
                                                            },
                                                            "iata_country_code": {
                                                              "type": "string",
                                                              "format": "ISO 3166-1 alpha-2",
                                                              "description": "The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\) code for the country where the city is located",
                                                              "example": "US"
                                                            }
                                                          }
                                                        }
                                                      }
                                                    }
                                                  }
                                                }
                                              },
                                              {
                                                "description": "The city or airport where this slice ends"
                                              }
                                            ]
                                          },
                                          "origin_type": {
                                            "type": "string",
                                            "description": "The type of the origin",
                                            "enum": [
                                              "airport",
                                              "city"
                                            ],
                                            "example": "airport"
                                          },
                                          "origin": {
                                            "allOf": [
                                              {
                                                "title": "Place",
                                                "type": "object",
                                                "properties": {
                                                  "iata_city_code": {
                                                    "type": "string",
                                                    "description": "The 3-letter IATA code for the city where the place is located. Only present for airports which are registered with IATA as belonging to a [metropolitan area](https://portal.iata.org/faq/articles/en_US/FAQ/How-do-I-create-a-new-Metropolitan-Area\).",
                                                    "example": "LON",
                                                    "nullable": true
                                                  },
                                                  "iata_code": {
                                                    "description": "The 3-letter IATA code for the place",
                                                    "type": "string",
                                                    "example": "LHR"
                                                  },
                                                  "id": {
                                                    "type": "string",
                                                    "description": "Duffel's unique identifier for the place",
                                                    "example": "arp_lhr_gb"
                                                  },
                                                  "name": {
                                                    "type": "string",
                                                    "description": "The name of the place",
                                                    "example": "Heathrow"
                                                  },
                                                  "type": {
                                                    "type": "string",
                                                    "enum": [
                                                      "airport",
                                                      "city"
                                                    ],
                                                    "description": "The type of the place",
                                                    "example": "airport"
                                                  },
                                                  "iata_country_code": {
                                                    "type": "string",
                                                    "format": "ISO 3166-1 alpha-2",
                                                    "description": "The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\) code for the country where the city is located",
                                                    "example": "GB"
                                                  },
                                                  "latitude": {
                                                    "type": "number",
                                                    "format": "float",
                                                    "description": "The latitude position of the airport represented in [Decimal degrees](https://en.wikipedia.org/wiki/Decimal_degrees\) with 6 decimal points with a range between -90° and 90°",
                                                    "example": 64.068865,
                                                    "nullable": true
                                                  },
                                                  "longitude": {
                                                    "type": "number",
                                                    "format": "float",
                                                    "description": "The longitude position of the airport represented in [Decimal degrees](https://en.wikipedia.org/wiki/Decimal_degrees\) with 6 decimal points with a range between -180° and 180°",
                                                    "example": -141.951519,
                                                    "nullable": true
                                                  },
                                                  "icao_code": {
                                                    "type": "string",
                                                    "description": "The four-character ICAO code for the airport",
                                                    "example": "EGLL",
                                                    "nullable": true
                                                  },
                                                  "time_zone": {
                                                    "type": "string",
                                                    "description": "The time zone of the airport, specified by name from the [tz database](https://en.wikipedia.org/wiki/Tz_database\)",
                                                    "example": "Europe/London",
                                                    "nullable": true
                                                  },
                                                  "city_name": {
                                                    "type": "string",
                                                    "description": "The name of the city (or cities separated by a `/`\) where the airport is located",
                                                    "example": "London",
                                                    "nullable": true
                                                  },
                                                  "city": {
                                                    "allOf": [
                                                      {
                                                        "title": "City",
                                                        "type": "object",
                                                        "description": "The metropolitan area where the airport is located. Only present for airports which are registered with IATA as belonging to a [metropolitan area](https://portal.iata.org/faq/articles/en_US/FAQ/How-do-I-create-a-new-Metropolitan-Area\).",
                                                        "properties": {
                                                          "iata_code": {
                                                            "type": "string",
                                                            "description": "The three-character IATA code for the city",
                                                            "example": "LON"
                                                          },
                                                          "id": {
                                                            "type": "string",
                                                            "description": "Duffel's unique identifier for the city",
                                                            "example": "cit_lon_gb"
                                                          },
                                                          "name": {
                                                            "type": "string",
                                                            "description": "The name of the city",
                                                            "example": "London"
                                                          },
                                                          "iata_country_code": {
                                                            "type": "string",
                                                            "format": "ISO 3166-1 alpha-2",
                                                            "description": "The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\) code for the country where the city is located",
                                                            "example": "GB"
                                                          }
                                                        }
                                                      },
                                                      {
                                                        "nullable": true
                                                      }
                                                    ]
                                                  },
                                                  "airports": {
                                                    "type": "array",
                                                    "description": "The airports associated to a city. This will only be provided where the `type` is `city`.",
                                                    "nullable": true,
                                                    "items": {
                                                      "title": "Airport",
                                                      "type": "object",
                                                      "properties": {
                                                        "iata_code": {
                                                          "type": "string",
                                                          "nullable": true,
                                                          "description": "The three-character IATA code for the airport",
                                                          "example": "LHR"
                                                        },
                                                        "id": {
                                                          "type": "string",
                                                          "description": "Duffel's unique identifier for the airport",
                                                          "example": "arp_lhr_gb"
                                                        },
                                                        "name": {
                                                          "type": "string",
                                                          "description": "The name of the airport",
                                                          "example": "Heathrow"
                                                        },
                                                        "iata_country_code": {
                                                          "type": "string",
                                                          "format": "ISO 3166-1 alpha-2",
                                                          "description": "The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\) code for the country where the airport is located",
                                                          "example": "GB"
                                                        },
                                                        "latitude": {
                                                          "type": "number",
                                                          "format": "float",
                                                          "description": "The latitude position of the airport represented in [Decimal degrees](https://en.wikipedia.org/wiki/Decimal_degrees\) with 6 decimal points with a range between -90° and 90°",
                                                          "example": 64.068865
                                                        },
                                                        "longitude": {
                                                          "type": "number",
                                                          "format": "float",
                                                          "description": "The longitude position of the airport represented in [Decimal degrees](https://en.wikipedia.org/wiki/Decimal_degrees\) with 6 decimal points with a range between -180° and 180°",
                                                          "example": -141.951519
                                                        },
                                                        "icao_code": {
                                                          "type": "string",
                                                          "nullable": true,
                                                          "description": "The four-character ICAO code for the airport",
                                                          "example": "EGLL"
                                                        },
                                                        "time_zone": {
                                                          "type": "string",
                                                          "description": "The time zone of the airport, specified by name from the [tz database](https://en.wikipedia.org/wiki/Tz_database\)",
                                                          "example": "Europe/London"
                                                        },
                                                        "city_name": {
                                                          "type": "string",
                                                          "description": "The name of the city (or cities separated by a `/`\) where the airport is located",
                                                          "example": "London"
                                                        },
                                                        "city": {
                                                          "nullable": true,
                                                          "title": "City",
                                                          "type": "object",
                                                          "description": "The metropolitan area where the airport is located. Only present for airports which are registered with IATA as belonging to a [metropolitan area](https://portal.iata.org/faq/articles/en_US/FAQ/How-do-I-create-a-new-Metropolitan-Area\).",
                                                          "properties": {
                                                            "iata_code": {
                                                              "type": "string",
                                                              "description": "The three-character IATA code for the city",
                                                              "example": "LON"
                                                            },
                                                            "id": {
                                                              "type": "string",
                                                              "description": "Duffel's unique identifier for the city",
                                                              "example": "cit_lon_gb"
                                                            },
                                                            "name": {
                                                              "type": "string",
                                                              "description": "The name of the city",
                                                              "example": "London"
                                                            },
                                                            "iata_country_code": {
                                                              "type": "string",
                                                              "format": "ISO 3166-1 alpha-2",
                                                              "description": "The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\) code for the country where the city is located",
                                                              "example": "GB"
                                                            }
                                                          }
                                                        }
                                                      }
                                                    }
                                                  }
                                                }
                                              },
                                              {
                                                "description": "The city or airport where this slice begins"
                                              }
                                            ]
                                          },
                                          "duration": {
                                            "type": "string",
                                            "nullable": true,
                                            "example": "PT02H26M",
                                            "description": "The duration of the slice, represented as a [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601#Durations\) duration"
                                          },
                                          "fare_brand_name": {
                                            "type": "string",
                                            "nullable": true,
                                            "example": "Basic",
                                            "description": "The name of the fare brand associated with this slice.\nA fare brand specifies the travel conditions you get on your slice made available by the airline.\ne.g. a British Airways Economy Basic fare will only include a hand baggage allowance.\nIt is worth noting that the fare brand names are defined by the airlines themselves and\ntherefore they are subject to change without any prior notice.\nWe’re in the process of adding support for `fare_brand_name` across all our airlines,\nso for now, this field may be `null` in some offers.\nThis will become a non-nullable attribute in the near future.\n"
                                          },
                                          "id": {
                                            "description": "Duffel's unique identifier for the slice. It identifies the slice of an offer (i.e. the same slice across offers will have different `id`s.\)",
                                            "type": "string",
                                            "example": "sli_00009htYpSCXrwaB9Dn123"
                                          },
                                          "segments": {
                                            "type": "array",
                                            "description": "The segments - that is, specific flights - that the airline is offering to get the passengers from the `origin` to the `destination`",
                                            "items": {
                                              "title": "Offer Slice Segment",
                                              "type": "object",
                                              "properties": {
                                                "aircraft": {
                                                  "allOf": [
                                                    {
                                                      "title": "Aircraft",
                                                      "type": "object",
                                                      "properties": {
                                                        "iata_code": {
                                                          "type": "string",
                                                          "description": "The three-character IATA code for the aircraft",
                                                          "example": "380"
                                                        },
                                                        "id": {
                                                          "type": "string",
                                                          "description": "Duffel's unique identifier for the aircraft",
                                                          "example": "arc_00009UhD4ongolulWd91Ky"
                                                        },
                                                        "name": {
                                                          "type": "string",
                                                          "description": "The name of the aircraft",
                                                          "example": "Airbus Industries A380"
                                                        }
                                                      }
                                                    },
                                                    {
                                                      "nullable": true,
                                                      "description": "The aircraft that the operating carrier will use to operate this segment"
                                                    }
                                                  ]
                                                },
                                                "arriving_at": {
                                                  "type": "string",
                                                  "format": "date-time",
                                                  "description": "The [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601\) datetime at which the segment is scheduled to arrive, in the destination airport timezone (see `destination.timezone`\)",
                                                  "example": "2020-06-13T16:38:02"
                                                },
                                                "destination_terminal": {
                                                  "type": "string",
                                                  "nullable": true,
                                                  "example": "5",
                                                  "description": "The terminal at the `destination` airport where the segment is scheduled to arrive"
                                                },
                                                "departing_at": {
                                                  "type": "string",
                                                  "format": "date-time",
                                                  "example": "2020-06-13T16:38:02",
                                                  "description": "The [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601\) datetime at which the segment is scheduled to depart, in the origin airport timezone (see `origin.timezone`\)"
                                                },
                                                "origin_terminal": {
                                                  "type": "string",
                                                  "nullable": true,
                                                  "example": "B",
                                                  "description": "The terminal at the `origin` airport from which the segment is scheduled to depart"
                                                },
                                                "destination": {
                                                  "allOf": [
                                                    {
                                                      "title": "Airport",
                                                      "type": "object",
                                                      "properties": {
                                                        "iata_code": {
                                                          "type": "string",
                                                          "nullable": true,
                                                          "description": "The three-character IATA code for the airport",
                                                          "example": "JFK"
                                                        },
                                                        "id": {
                                                          "type": "string",
                                                          "description": "Duffel's unique identifier for the airport",
                                                          "example": "arp_jfk_us"
                                                        },
                                                        "name": {
                                                          "type": "string",
                                                          "description": "The name of the airport",
                                                          "example": "John F. Kennedy International Airport"
                                                        },
                                                        "iata_country_code": {
                                                          "type": "string",
                                                          "format": "ISO 3166-1 alpha-2",
                                                          "description": "The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\) code for the country where the airport is located",
                                                          "example": "US"
                                                        },
                                                        "latitude": {
                                                          "type": "number",
                                                          "format": "float",
                                                          "description": "The latitude position of the airport represented in [Decimal degrees](https://en.wikipedia.org/wiki/Decimal_degrees\) with 6 decimal points with a range between -90° and 90°",
                                                          "example": 40.640556
                                                        },
                                                        "longitude": {
                                                          "type": "number",
                                                          "format": "float",
                                                          "description": "The longitude position of the airport represented in [Decimal degrees](https://en.wikipedia.org/wiki/Decimal_degrees\) with 6 decimal points with a range between -180° and 180°",
                                                          "example": -73.778519
                                                        },
                                                        "icao_code": {
                                                          "type": "string",
                                                          "nullable": true,
                                                          "description": "The four-character ICAO code for the airport",
                                                          "example": "KJFK"
                                                        },
                                                        "time_zone": {
                                                          "type": "string",
                                                          "description": "The time zone of the airport, specified by name from the [tz database](https://en.wikipedia.org/wiki/Tz_database\)",
                                                          "example": "America/New_York"
                                                        },
                                                        "city_name": {
                                                          "type": "string",
                                                          "description": "The name of the city (or cities separated by a `/`\) where the airport is located",
                                                          "example": "New York"
                                                        },
                                                        "city": {
                                                          "nullable": true,
                                                          "title": "City",
                                                          "type": "object",
                                                          "description": "The metropolitan area where the airport is located. Only present for airports which are registered with IATA as belonging to a [metropolitan area](https://portal.iata.org/faq/articles/en_US/FAQ/How-do-I-create-a-new-Metropolitan-Area\).",
                                                          "properties": {
                                                            "iata_code": {
                                                              "type": "string",
                                                              "description": "The three-character IATA code for the city",
                                                              "example": "NYC"
                                                            },
                                                            "id": {
                                                              "type": "string",
                                                              "description": "Duffel's unique identifier for the city",
                                                              "example": "cit_nyc_us"
                                                            },
                                                            "name": {
                                                              "type": "string",
                                                              "description": "The name of the city",
                                                              "example": "New York"
                                                            },
                                                            "iata_country_code": {
                                                              "type": "string",
                                                              "format": "ISO 3166-1 alpha-2",
                                                              "description": "The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\) code for the country where the city is located",
                                                              "example": "US"
                                                            }
                                                          }
                                                        }
                                                      }
                                                    },
                                                    {
                                                      "description": "The airport at which the segment is scheduled to arrive"
                                                    }
                                                  ]
                                                },
                                                "distance": {
                                                  "type": "string",
                                                  "nullable": true,
                                                  "description": "The distance of the segment in kilometres",
                                                  "example": "424.2"
                                                },
                                                "duration": {
                                                  "type": "string",
                                                  "nullable": true,
                                                  "example": "PT02H26M",
                                                  "description": "The duration of the segment, represented as a [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601#Durations\) duration"
                                                },
                                                "id": {
                                                  "description": "Duffel's unique identifier for the segment. It identifies the segment of an offer (i.e. the same segment across offers will have different `id`s\).",
                                                  "type": "string",
                                                  "example": "seg_00009htYpSCXrwaB9Dn456"
                                                },
                                                "marketing_carrier": {
                                                  "allOf": [
                                                    {
                                                      "title": "Airline",
                                                      "type": "object",
                                                      "properties": {
                                                        "iata_code": {
                                                          "type": "string",
                                                          "nullable": true,
                                                          "description": "The two-character IATA code for the airline. This may be `null` for non-IATA carriers.",
                                                          "example": "BA"
                                                        },
                                                        "id": {
                                                          "type": "string",
                                                          "description": "Duffel's unique identifier for the airline",
                                                          "example": "aln_00001876aqC8c5umZmrRds"
                                                        },
                                                        "name": {
                                                          "type": "string",
                                                          "description": "The name of the airline",
                                                          "example": "British Airways"
                                                        }
                                                      }
                                                    },
                                                    {
                                                      "description": "The airline selling the tickets for this segment. This may differ from the `operating_carrier` in the case of a \"codeshare\", where one airline sells flights operated by another airline."
                                                    }
                                                  ]
                                                },
                                                "marketing_carrier_flight_number": {
                                                  "type": "string",
                                                  "example": "1234",
                                                  "description": "The flight number assigned by the marketing carrier"
                                                },
                                                "origin": {
                                                  "allOf": [
                                                    {
                                                      "title": "Airport",
                                                      "type": "object",
                                                      "properties": {
                                                        "iata_code": {
                                                          "type": "string",
                                                          "nullable": true,
                                                          "description": "The three-character IATA code for the airport",
                                                          "example": "LHR"
                                                        },
                                                        "id": {
                                                          "type": "string",
                                                          "description": "Duffel's unique identifier for the airport",
                                                          "example": "arp_lhr_gb"
                                                        },
                                                        "name": {
                                                          "type": "string",
                                                          "description": "The name of the airport",
                                                          "example": "Heathrow"
                                                        },
                                                        "iata_country_code": {
                                                          "type": "string",
                                                          "format": "ISO 3166-1 alpha-2",
                                                          "description": "The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\) code for the country where the airport is located",
                                                          "example": "GB"
                                                        },
                                                        "latitude": {
                                                          "type": "number",
                                                          "format": "float",
                                                          "description": "The latitude position of the airport represented in [Decimal degrees](https://en.wikipedia.org/wiki/Decimal_degrees\) with 6 decimal points with a range between -90° and 90°",
                                                          "example": 64.068865
                                                        },
                                                        "longitude": {
                                                          "type": "number",
                                                          "format": "float",
                                                          "description": "The longitude position of the airport represented in [Decimal degrees](https://en.wikipedia.org/wiki/Decimal_degrees\) with 6 decimal points with a range between -180° and 180°",
                                                          "example": -141.951519
                                                        },
                                                        "icao_code": {
                                                          "type": "string",
                                                          "nullable": true,
                                                          "description": "The four-character ICAO code for the airport",
                                                          "example": "EGLL"
                                                        },
                                                        "time_zone": {
                                                          "type": "string",
                                                          "description": "The time zone of the airport, specified by name from the [tz database](https://en.wikipedia.org/wiki/Tz_database\)",
                                                          "example": "Europe/London"
                                                        },
                                                        "city_name": {
                                                          "type": "string",
                                                          "description": "The name of the city (or cities separated by a `/`\) where the airport is located",
                                                          "example": "London"
                                                        },
                                                        "city": {
                                                          "nullable": true,
                                                          "title": "City",
                                                          "type": "object",
                                                          "description": "The metropolitan area where the airport is located. Only present for airports which are registered with IATA as belonging to a [metropolitan area](https://portal.iata.org/faq/articles/en_US/FAQ/How-do-I-create-a-new-Metropolitan-Area\).",
                                                          "properties": {
                                                            "iata_code": {
                                                              "type": "string",
                                                              "description": "The three-character IATA code for the city",
                                                              "example": "LON"
                                                            },
                                                            "id": {
                                                              "type": "string",
                                                              "description": "Duffel's unique identifier for the city",
                                                              "example": "cit_lon_gb"
                                                            },
                                                            "name": {
                                                              "type": "string",
                                                              "description": "The name of the city",
                                                              "example": "London"
                                                            },
                                                            "iata_country_code": {
                                                              "type": "string",
                                                              "format": "ISO 3166-1 alpha-2",
                                                              "description": "The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\) code for the country where the city is located",
                                                              "example": "GB"
                                                            }
                                                          }
                                                        }
                                                      }
                                                    },
                                                    {
                                                      "description": "The airport from which the flight is scheduled to depart"
                                                    }
                                                  ]
                                                },
                                                "operating_carrier": {
                                                  "allOf": [
                                                    {
                                                      "title": "Airline",
                                                      "type": "object",
                                                      "properties": {
                                                        "iata_code": {
                                                          "type": "string",
                                                          "nullable": true,
                                                          "description": "The two-character IATA code for the airline. This may be `null` for non-IATA carriers.",
                                                          "example": "BA"
                                                        },
                                                        "id": {
                                                          "type": "string",
                                                          "description": "Duffel's unique identifier for the airline",
                                                          "example": "aln_00001876aqC8c5umZmrRds"
                                                        },
                                                        "name": {
                                                          "type": "string",
                                                          "description": "The name of the airline",
                                                          "example": "British Airways"
                                                        }
                                                      }
                                                    },
                                                    {
                                                      "description": "The airline actually operating this segment. This may differ from the `marketing_carrier` in the case of a \"codeshare\", where one airline sells flights operated by another airline."
                                                    }
                                                  ]
                                                },
                                                "operating_carrier_flight_number": {
                                                  "type": "string",
                                                  "example": "4321",
                                                  "description": "The flight number assigned by the operating carrier. This may not be present, in which case you should display the `marketing_carrier`'s information and the `marketing_carrier_flight_number`, and simply state the name of the `operating_carrier`.",
                                                  "nullable": true
                                                },
                                                "passengers": {
                                                  "type": "array",
                                                  "description": "Additional segment-specific information about the passengers included in the offer (e.g. their baggage allowance and the cabin class they will be travelling in\)",
                                                  "items": {
                                                    "title": "Offer Slice Segment Passenger",
                                                    "type": "object",
                                                    "properties": {
                                                      "baggages": {
                                                        "type": "array",
                                                        "items": {
                                                          "title": "Slice Segment Passenger Baggage",
                                                          "type": "object",
                                                          "properties": {
                                                            "type": {
                                                              "type": "string",
                                                              "enum": [
                                                                "checked",
                                                                "carry_on"
                                                              ],
                                                              "description": "The type of the baggage allowance",
                                                              "example": "checked"
                                                            },
                                                            "quantity": {
                                                              "type": "integer",
                                                              "description": "The number of this type of bag allowed on the segment. Note that this can currently be 0 in some cases.",
                                                              "example": 1
                                                            }
                                                          }
                                                        },
                                                        "description": "The baggage allowances for the passenger on this segment included in the offer. Some airlines may allow additional baggage to be booked as a service - see the offer's `available_services`."
                                                      },
                                                      "cabin_class": {
                                                        "type": "string",
                                                        "enum": [
                                                          "first",
                                                          "business",
                                                          "premium_economy",
                                                          "economy"
                                                        ],
                                                        "description": "The cabin class that the passenger will travel in on this segment",
                                                        "example": "economy"
                                                      },
                                                      "cabin_class_marketing_name": {
                                                        "type": "string",
                                                        "description": "The name that the marketing carrier uses to market this cabin class",
                                                        "example": "Economy Basic"
                                                      },
                                                      "passenger_id": {
                                                        "type": "string",
                                                        "description": "The identifier for the passenger. You may have specified this ID yourself when creating the offer request, or otherwise, Duffel will have generated its own random ID.",
                                                        "example": "passenger_0"
                                                      },
                                                      "fare_basis_code": {
                                                        "type": "string",
                                                        "description": "The airline's alphanumeric code for the fare that the passenger is using to travel. Where this is `null`, it means that either the fare basis code is not available or the airline does not use fare basis codes.",
                                                        "example": "OXZ0RO",
                                                        "nullable": true
                                                      }
                                                    }
                                                  }
                                                }
                                              }
                                            }
                                          },
                                          "conditions": {
                                            "type": "object",
                                            "title": "OfferSliceConditions",
                                            "description": "The conditions associated with this slice, describing the kinds of modifications you can make post-booking and any penalties that will apply to those modifications.\nThis condition is applied only to this slice and to all the passengers associated with this offer - for information at the offer level (e.g. \"what happens if I want to change all the slices?\"\) refer to the `conditions` at the top level.\nIf a particular kind of modification is allowed, you may not always be able to take action through the Duffel API. In some cases, you may need to contact the Duffel support team or the airline directly.\n",
                                            "properties": {
                                              "change_before_departure": {
                                                "type": "object",
                                                "nullable": true,
                                                "description": "Whether this slice can be changed before the departure.\nIf the slice can be changed for all of the passengers then the `allowed` property will be `true` and information will be provided about any penalties.\nIf none of the passengers on the slice can be changed then the `allowed` property will be `false`.\nIn all other cases this property will be `null` indicating we can't provide the information for this slice.\nThe `penalty_amount` is specific to changing this slice and may not be the penalty that is applied if the entire offer is changed.\n",
                                                "properties": {
                                                  "allowed": {
                                                    "description": "Whether this kind of modification is allowed post-booking",
                                                    "nullable": false,
                                                    "type": "boolean",
                                                    "example": true
                                                  },
                                                  "penalty_amount": {
                                                    "description": "If the modification is `allowed` then this is the amount payable to apply the modification to all passengers. If there is no penalty, the value will be zero.\nIf the modification isn't `allowed` or the penalty is not known then this field will be `null`.\nIf this is `null` then the `penalty_currency` will also be `null`.\n",
                                                    "nullable": true,
                                                    "type": "string",
                                                    "example": "100.00"
                                                  },
                                                  "penalty_currency": {
                                                    "description": "The currency of the `penalty_amount` as an [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217\) currency code.\nThis will be in a currency determined by the airline, which is not necessarily the same as the currency of the offer or order.\nIf this is `null` then `penalty_amount` will also be `null`.\n",
                                                    "example": "GBP",
                                                    "format": "ISO 4217",
                                                    "nullable": true,
                                                    "type": "string"
                                                  }
                                                }
                                              }
                                            }
                                          }
                                        }
                                      }
                                    },
                                    "tax_amount": {
                                      "description": "The amount of tax payable on the offer for all passengers",
                                      "type": "string",
                                      "nullable": true,
                                      "example": "40.80"
                                    },
                                    "tax_currency": {
                                      "description": "The currency of the `tax_amount`, as an [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217\) currency code.\nIt will match your organisation's billing currency unless you’re using Duffel as an accredited IATA agent, in which case it will be in the currency provided by the airline (which will usually be based on the country where your IATA agency is registered\).\n",
                                      "example": "GBP",
                                      "type": "string",
                                      "format": "ISO 4217",
                                      "nullable": true
                                    },
                                    "total_amount": {
                                      "description": "The total price of the offer for all passengers, including taxes. It does not include the total price of any service(s\) that might be booked with the offer.",
                                      "type": "string",
                                      "example": "45.00"
                                    },
                                    "total_emissions_kg": {
                                      "description": "An estimate of the total carbon dioxide (CO₂\) emissions when all of the passengers fly this offer's itinerary, measured in kilograms",
                                      "type": "string",
                                      "example": "460"
                                    },
                                    "total_currency": {
                                      "description": "The currency of the `total_amount`, as an [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217\) currency code.\nIt will match your organisation's billing currency unless you’re using Duffel as an accredited IATA agent, in which case it will be in the currency provided by the airline (which will usually be based on the country where your IATA agency is registered\).\n",
                                      "type": "string",
                                      "format": "ISO 4217",
                                      "example": "GBP"
                                    }
                                  }
                                }
                              },
                              "slices": {
                                "description": "The [slices](/docs/api/overview/key-principles\) that make up this offer request. One-way journeys can be expressed using one slice, whereas return trips will need two.",
                                "type": "array",
                                "items": {
                                  "title": "Offer Request Slice",
                                  "type": "object",
                                  "properties": {
                                    "destination_type": {
                                      "type": "string",
                                      "description": "The type of the destination",
                                      "enum": [
                                        "airport",
                                        "city"
                                      ],
                                      "example": "airport"
                                    },
                                    "destination": {
                                      "allOf": [
                                        {
                                          "title": "Place",
                                          "type": "object",
                                          "properties": {
                                            "iata_city_code": {
                                              "type": "string",
                                              "description": "The 3-letter IATA code for the city where the place is located. Only present for airports which are registered with IATA as belonging to a [metropolitan area](https://portal.iata.org/faq/articles/en_US/FAQ/How-do-I-create-a-new-Metropolitan-Area\).",
                                              "example": "NYC",
                                              "nullable": true
                                            },
                                            "iata_code": {
                                              "description": "The 3-letter IATA code for the place",
                                              "type": "string",
                                              "example": "JFK"
                                            },
                                            "id": {
                                              "type": "string",
                                              "description": "Duffel's unique identifier for the place",
                                              "example": "arp_jfk_us"
                                            },
                                            "name": {
                                              "type": "string",
                                              "description": "The name of the place",
                                              "example": "John F. Kennedy International Airport"
                                            },
                                            "type": {
                                              "type": "string",
                                              "enum": [
                                                "airport",
                                                "city"
                                              ],
                                              "description": "The type of the place",
                                              "example": "airport"
                                            },
                                            "iata_country_code": {
                                              "type": "string",
                                              "format": "ISO 3166-1 alpha-2",
                                              "description": "The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\) code for the country where the city is located",
                                              "example": "US"
                                            },
                                            "latitude": {
                                              "type": "number",
                                              "format": "float",
                                              "description": "The latitude position of the airport represented in [Decimal degrees](https://en.wikipedia.org/wiki/Decimal_degrees\) with 6 decimal points with a range between -90° and 90°",
                                              "example": 40.640556,
                                              "nullable": true
                                            },
                                            "longitude": {
                                              "type": "number",
                                              "format": "float",
                                              "description": "The longitude position of the airport represented in [Decimal degrees](https://en.wikipedia.org/wiki/Decimal_degrees\) with 6 decimal points with a range between -180° and 180°",
                                              "example": -73.778519,
                                              "nullable": true
                                            },
                                            "icao_code": {
                                              "type": "string",
                                              "description": "The four-character ICAO code for the airport",
                                              "example": "KJFK",
                                              "nullable": true
                                            },
                                            "time_zone": {
                                              "type": "string",
                                              "description": "The time zone of the airport, specified by name from the [tz database](https://en.wikipedia.org/wiki/Tz_database\)",
                                              "example": "America/New_York",
                                              "nullable": true
                                            },
                                            "city_name": {
                                              "type": "string",
                                              "description": "The name of the city (or cities separated by a `/`\) where the airport is located",
                                              "example": "New York",
                                              "nullable": true
                                            },
                                            "city": {
                                              "allOf": [
                                                {
                                                  "title": "City",
                                                  "type": "object",
                                                  "description": "The metropolitan area where the airport is located. Only present for airports which are registered with IATA as belonging to a [metropolitan area](https://portal.iata.org/faq/articles/en_US/FAQ/How-do-I-create-a-new-Metropolitan-Area\).",
                                                  "properties": {
                                                    "iata_code": {
                                                      "type": "string",
                                                      "description": "The three-character IATA code for the city",
                                                      "example": "NYC"
                                                    },
                                                    "id": {
                                                      "type": "string",
                                                      "description": "Duffel's unique identifier for the city",
                                                      "example": "cit_nyc_us"
                                                    },
                                                    "name": {
                                                      "type": "string",
                                                      "description": "The name of the city",
                                                      "example": "New York"
                                                    },
                                                    "iata_country_code": {
                                                      "type": "string",
                                                      "format": "ISO 3166-1 alpha-2",
                                                      "description": "The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\) code for the country where the city is located",
                                                      "example": "US"
                                                    }
                                                  }
                                                },
                                                {
                                                  "nullable": true
                                                }
                                              ]
                                            },
                                            "airports": {
                                              "type": "array",
                                              "description": "The airports associated to a city. This will only be provided where the `type` is `city`.",
                                              "nullable": true,
                                              "items": {
                                                "title": "Airport",
                                                "type": "object",
                                                "properties": {
                                                  "iata_code": {
                                                    "type": "string",
                                                    "nullable": true,
                                                    "description": "The three-character IATA code for the airport",
                                                    "example": "JFK"
                                                  },
                                                  "id": {
                                                    "type": "string",
                                                    "description": "Duffel's unique identifier for the airport",
                                                    "example": "arp_jfk_us"
                                                  },
                                                  "name": {
                                                    "type": "string",
                                                    "description": "The name of the airport",
                                                    "example": "John F. Kennedy International Airport"
                                                  },
                                                  "iata_country_code": {
                                                    "type": "string",
                                                    "format": "ISO 3166-1 alpha-2",
                                                    "description": "The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\) code for the country where the airport is located",
                                                    "example": "US"
                                                  },
                                                  "latitude": {
                                                    "type": "number",
                                                    "format": "float",
                                                    "description": "The latitude position of the airport represented in [Decimal degrees](https://en.wikipedia.org/wiki/Decimal_degrees\) with 6 decimal points with a range between -90° and 90°",
                                                    "example": 40.640556
                                                  },
                                                  "longitude": {
                                                    "type": "number",
                                                    "format": "float",
                                                    "description": "The longitude position of the airport represented in [Decimal degrees](https://en.wikipedia.org/wiki/Decimal_degrees\) with 6 decimal points with a range between -180° and 180°",
                                                    "example": -73.778519
                                                  },
                                                  "icao_code": {
                                                    "type": "string",
                                                    "nullable": true,
                                                    "description": "The four-character ICAO code for the airport",
                                                    "example": "KJFK"
                                                  },
                                                  "time_zone": {
                                                    "type": "string",
                                                    "description": "The time zone of the airport, specified by name from the [tz database](https://en.wikipedia.org/wiki/Tz_database\)",
                                                    "example": "America/New_York"
                                                  },
                                                  "city_name": {
                                                    "type": "string",
                                                    "description": "The name of the city (or cities separated by a `/`\) where the airport is located",
                                                    "example": "New York"
                                                  },
                                                  "city": {
                                                    "nullable": true,
                                                    "title": "City",
                                                    "type": "object",
                                                    "description": "The metropolitan area where the airport is located. Only present for airports which are registered with IATA as belonging to a [metropolitan area](https://portal.iata.org/faq/articles/en_US/FAQ/How-do-I-create-a-new-Metropolitan-Area\).",
                                                    "properties": {
                                                      "iata_code": {
                                                        "type": "string",
                                                        "description": "The three-character IATA code for the city",
                                                        "example": "NYC"
                                                      },
                                                      "id": {
                                                        "type": "string",
                                                        "description": "Duffel's unique identifier for the city",
                                                        "example": "cit_nyc_us"
                                                      },
                                                      "name": {
                                                        "type": "string",
                                                        "description": "The name of the city",
                                                        "example": "New York"
                                                      },
                                                      "iata_country_code": {
                                                        "type": "string",
                                                        "format": "ISO 3166-1 alpha-2",
                                                        "description": "The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\) code for the country where the city is located",
                                                        "example": "US"
                                                      }
                                                    }
                                                  }
                                                }
                                              }
                                            }
                                          }
                                        },
                                        {
                                          "description": "The city or airport the passengers want to travel to"
                                        }
                                      ]
                                    },
                                    "origin_type": {
                                      "type": "string",
                                      "description": "The type of the origin",
                                      "enum": [
                                        "airport",
                                        "city"
                                      ],
                                      "example": "airport"
                                    },
                                    "origin": {
                                      "allOf": [
                                        {
                                          "title": "Place",
                                          "type": "object",
                                          "properties": {
                                            "iata_city_code": {
                                              "type": "string",
                                              "description": "The 3-letter IATA code for the city where the place is located. Only present for airports which are registered with IATA as belonging to a [metropolitan area](https://portal.iata.org/faq/articles/en_US/FAQ/How-do-I-create-a-new-Metropolitan-Area\).",
                                              "example": "LON",
                                              "nullable": true
                                            },
                                            "iata_code": {
                                              "description": "The 3-letter IATA code for the place",
                                              "type": "string",
                                              "example": "LHR"
                                            },
                                            "id": {
                                              "type": "string",
                                              "description": "Duffel's unique identifier for the place",
                                              "example": "arp_lhr_gb"
                                            },
                                            "name": {
                                              "type": "string",
                                              "description": "The name of the place",
                                              "example": "Heathrow"
                                            },
                                            "type": {
                                              "type": "string",
                                              "enum": [
                                                "airport",
                                                "city"
                                              ],
                                              "description": "The type of the place",
                                              "example": "airport"
                                            },
                                            "iata_country_code": {
                                              "type": "string",
                                              "format": "ISO 3166-1 alpha-2",
                                              "description": "The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\) code for the country where the city is located",
                                              "example": "GB"
                                            },
                                            "latitude": {
                                              "type": "number",
                                              "format": "float",
                                              "description": "The latitude position of the airport represented in [Decimal degrees](https://en.wikipedia.org/wiki/Decimal_degrees\) with 6 decimal points with a range between -90° and 90°",
                                              "example": 64.068865,
                                              "nullable": true
                                            },
                                            "longitude": {
                                              "type": "number",
                                              "format": "float",
                                              "description": "The longitude position of the airport represented in [Decimal degrees](https://en.wikipedia.org/wiki/Decimal_degrees\) with 6 decimal points with a range between -180° and 180°",
                                              "example": -141.951519,
                                              "nullable": true
                                            },
                                            "icao_code": {
                                              "type": "string",
                                              "description": "The four-character ICAO code for the airport",
                                              "example": "EGLL",
                                              "nullable": true
                                            },
                                            "time_zone": {
                                              "type": "string",
                                              "description": "The time zone of the airport, specified by name from the [tz database](https://en.wikipedia.org/wiki/Tz_database\)",
                                              "example": "Europe/London",
                                              "nullable": true
                                            },
                                            "city_name": {
                                              "type": "string",
                                              "description": "The name of the city (or cities separated by a `/`\) where the airport is located",
                                              "example": "London",
                                              "nullable": true
                                            },
                                            "city": {
                                              "allOf": [
                                                {
                                                  "title": "City",
                                                  "type": "object",
                                                  "description": "The metropolitan area where the airport is located. Only present for airports which are registered with IATA as belonging to a [metropolitan area](https://portal.iata.org/faq/articles/en_US/FAQ/How-do-I-create-a-new-Metropolitan-Area\).",
                                                  "properties": {
                                                    "iata_code": {
                                                      "type": "string",
                                                      "description": "The three-character IATA code for the city",
                                                      "example": "LON"
                                                    },
                                                    "id": {
                                                      "type": "string",
                                                      "description": "Duffel's unique identifier for the city",
                                                      "example": "cit_lon_gb"
                                                    },
                                                    "name": {
                                                      "type": "string",
                                                      "description": "The name of the city",
                                                      "example": "London"
                                                    },
                                                    "iata_country_code": {
                                                      "type": "string",
                                                      "format": "ISO 3166-1 alpha-2",
                                                      "description": "The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\) code for the country where the city is located",
                                                      "example": "GB"
                                                    }
                                                  }
                                                },
                                                {
                                                  "nullable": true
                                                }
                                              ]
                                            },
                                            "airports": {
                                              "type": "array",
                                              "description": "The airports associated to a city. This will only be provided where the `type` is `city`.",
                                              "nullable": true,
                                              "items": {
                                                "title": "Airport",
                                                "type": "object",
                                                "properties": {
                                                  "iata_code": {
                                                    "type": "string",
                                                    "nullable": true,
                                                    "description": "The three-character IATA code for the airport",
                                                    "example": "LHR"
                                                  },
                                                  "id": {
                                                    "type": "string",
                                                    "description": "Duffel's unique identifier for the airport",
                                                    "example": "arp_lhr_gb"
                                                  },
                                                  "name": {
                                                    "type": "string",
                                                    "description": "The name of the airport",
                                                    "example": "Heathrow"
                                                  },
                                                  "iata_country_code": {
                                                    "type": "string",
                                                    "format": "ISO 3166-1 alpha-2",
                                                    "description": "The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\) code for the country where the airport is located",
                                                    "example": "GB"
                                                  },
                                                  "latitude": {
                                                    "type": "number",
                                                    "format": "float",
                                                    "description": "The latitude position of the airport represented in [Decimal degrees](https://en.wikipedia.org/wiki/Decimal_degrees\) with 6 decimal points with a range between -90° and 90°",
                                                    "example": 64.068865
                                                  },
                                                  "longitude": {
                                                    "type": "number",
                                                    "format": "float",
                                                    "description": "The longitude position of the airport represented in [Decimal degrees](https://en.wikipedia.org/wiki/Decimal_degrees\) with 6 decimal points with a range between -180° and 180°",
                                                    "example": -141.951519
                                                  },
                                                  "icao_code": {
                                                    "type": "string",
                                                    "nullable": true,
                                                    "description": "The four-character ICAO code for the airport",
                                                    "example": "EGLL"
                                                  },
                                                  "time_zone": {
                                                    "type": "string",
                                                    "description": "The time zone of the airport, specified by name from the [tz database](https://en.wikipedia.org/wiki/Tz_database\)",
                                                    "example": "Europe/London"
                                                  },
                                                  "city_name": {
                                                    "type": "string",
                                                    "description": "The name of the city (or cities separated by a `/`\) where the airport is located",
                                                    "example": "London"
                                                  },
                                                  "city": {
                                                    "nullable": true,
                                                    "title": "City",
                                                    "type": "object",
                                                    "description": "The metropolitan area where the airport is located. Only present for airports which are registered with IATA as belonging to a [metropolitan area](https://portal.iata.org/faq/articles/en_US/FAQ/How-do-I-create-a-new-Metropolitan-Area\).",
                                                    "properties": {
                                                      "iata_code": {
                                                        "type": "string",
                                                        "description": "The three-character IATA code for the city",
                                                        "example": "LON"
                                                      },
                                                      "id": {
                                                        "type": "string",
                                                        "description": "Duffel's unique identifier for the city",
                                                        "example": "cit_lon_gb"
                                                      },
                                                      "name": {
                                                        "type": "string",
                                                        "description": "The name of the city",
                                                        "example": "London"
                                                      },
                                                      "iata_country_code": {
                                                        "type": "string",
                                                        "format": "ISO 3166-1 alpha-2",
                                                        "description": "The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\) code for the country where the city is located",
                                                        "example": "GB"
                                                      }
                                                    }
                                                  }
                                                }
                                              }
                                            }
                                          }
                                        },
                                        {
                                          "description": "The city or airport the passengers want to depart from"
                                        }
                                      ]
                                    },
                                    "departure_date": {
                                      "type": "string",
                                      "format": "date",
                                      "description": "The [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601\) date on which the passengers want to depart",
                                      "example": "2020-04-24"
                                    }
                                  }
                                }
                              },
                              "passengers": {
                                "description": "The passengers who want to travel",
                                "type": "array",
                                "items": {
                                  "type": "object",
                                  "title": "Offer Request Passenger",
                                  "properties": {
                                    "age": {
                                      "type": "integer",
                                      "description": "The age of the passenger on the `departure_date` of the final slice",
                                      "example": 14,
                                      "minimum": 0,
                                      "maximum": 130
                                    },
                                    "type": {
                                      "type": "string",
                                      "description": "The type of the passenger",
                                      "enum": [
                                        "adult",
                                        "child",
                                        "infant_without_seat"
                                      ],
                                      "example": "adult"
                                    },
                                    "id": {
                                      "type": "string",
                                      "description": "The identifier for the passenger, unique within this Offer Request and across all Offer Requests. This ID will be generated by Duffel. Optionally providing an ID has been deprecated.",
                                      "example": "pas_00009hj8USM7Ncg31cBCL"
                                    },
                                    "given_name": {
                                      "type": "string",
                                      "nullable": true,
                                      "description": "The passenger's given name. Only `space`, `-`, `'`, and letters from the [`ASCII`](https://www.unicode.org/charts/PDF/U0000.pdf\), [`Latin-1 Supplement`](https://www.unicode.org/charts/PDF/U0080.pdf\) and [`Latin Extended-A`](https://www.unicode.org/charts/PDF/U0100.pdf\) (with the exceptions of `Æ`, `æ`, `Ĳ`, `ĳ`, `Œ`, `œ`, `Þ`, and `ð`\) Unicode charts are accepted. All other characters will result in a validation error. The minimum length is 1 character, and the maximum is 20 characters.\n\nThis is only required if you're also including __Loyalty Programme Accounts__.\n",
                                      "example": "Amelia"
                                    },
                                    "family_name": {
                                      "nullable": true,
                                      "type": "string",
                                      "description": "The passenger's family name. Only `space`, `-`, `'`, and letters from the [`ASCII`](https://www.unicode.org/charts/PDF/U0000.pdf\), [`Latin-1 Supplement`](https://www.unicode.org/charts/PDF/U0080.pdf\) and [`Latin Extended-A`](https://www.unicode.org/charts/PDF/U0100.pdf\) (with the exceptions of `Æ`, `æ`, `Ĳ`, `ĳ`, `Œ`, `œ`, `Þ`, and `ð`\) Unicode charts are accepted. All other characters will result in a validation error. The minimum length is 1 character, and the maximum is 20 characters.\n\nThis is only required if you're also including __Loyalty Programme Accounts__.\n",
                                      "example": "Earhart"
                                    },
                                    "loyalty_programme_accounts": {
                                      "type": "array",
                                      "description": "The __Loyalty Programme Accounts__ for this passenger",
                                      "items": {
                                        "type": "object",
                                        "title": "Loyalty Programme Account",
                                        "properties": {
                                          "airline_iata_code": {
                                            "type": "string",
                                            "description": "The IATA code for the airline that this __Loyalty Programme Account__ belongs to",
                                            "example": "BA"
                                          },
                                          "account_number": {
                                            "type": "string",
                                            "description": "The passenger's account number for this __Loyalty Programme Account__",
                                            "example": "12901014"
                                          }
                                        }
                                      }
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      })

      assert DataSchema.OpenApi.schemas_from_open_api_json(json) == %{
               "POST RESPONSECreateOfferRequest" => [
                 has_one:
                   {:data, "data",
                    [
                      has_many:
                        {:slices, "slices",
                         [
                           field: {:origin_type, "origin_type", "string"},
                           field: {:type, "type", "string"},
                           field: {:time_zone, "time_zone", "string"},
                           field: {:name, "name", "string"},
                           field: {:longitude, "longitude", "integer"},
                           field: {:latitude, "latitude", "integer"},
                           field: {:id, "id", "string"},
                           field: {:icao_code, "icao_code", "string"},
                           field: {:iata_country_code, "iata_country_code", "string"},
                           field: {:iata_code, "iata_code", "string"},
                           field: {:iata_city_code, "iata_city_code", "string"},
                           field: {:city_name, "city_name", "string"},
                           field: {:name, "name", "string"},
                           field: {:id, "id", "string"},
                           field: {:iata_country_code, "iata_country_code", "string"},
                           field: {:iata_code, "iata_code", "string"},
                           has_many:
                             {:airports, "airports",
                              [
                                field: {:time_zone, "time_zone", "string"},
                                field: {:name, "name", "string"},
                                field: {:longitude, "longitude", "integer"},
                                field: {:latitude, "latitude", "integer"},
                                field: {:id, "id", "string"},
                                field: {:icao_code, "icao_code", "string"},
                                field: {:iata_country_code, "iata_country_code", "string"},
                                field: {:iata_code, "iata_code", "string"},
                                field: {:city_name, "city_name", "string"},
                                has_one:
                                  {:city, "city",
                                   [
                                     field: {:name, "name", "string"},
                                     field: {:id, "id", "string"},
                                     field: {:iata_country_code, "iata_country_code", "string"},
                                     field: {:iata_code, "iata_code", "string"}
                                   ]}
                              ]},
                           field: {:destination_type, "destination_type", "string"},
                           field: {:type, "type", "string"},
                           field: {:time_zone, "time_zone", "string"},
                           field: {:name, "name", "string"},
                           field: {:longitude, "longitude", "integer"},
                           field: {:latitude, "latitude", "integer"},
                           field: {:id, "id", "string"},
                           field: {:icao_code, "icao_code", "string"},
                           field: {:iata_country_code, "iata_country_code", "string"},
                           field: {:iata_code, "iata_code", "string"},
                           field: {:iata_city_code, "iata_city_code", "string"},
                           field: {:city_name, "city_name", "string"},
                           field: {:name, "name", "string"},
                           field: {:id, "id", "string"},
                           field: {:iata_country_code, "iata_country_code", "string"},
                           field: {:iata_code, "iata_code", "string"},
                           has_many:
                             {:airports, "airports",
                              [
                                field: {:time_zone, "time_zone", "string"},
                                field: {:name, "name", "string"},
                                field: {:longitude, "longitude", "integer"},
                                field: {:latitude, "latitude", "integer"},
                                field: {:id, "id", "string"},
                                field: {:icao_code, "icao_code", "string"},
                                field: {:iata_country_code, "iata_country_code", "string"},
                                field: {:iata_code, "iata_code", "string"},
                                field: {:city_name, "city_name", "string"},
                                has_one:
                                  {:city, "city",
                                   [
                                     field: {:name, "name", "string"},
                                     field: {:id, "id", "string"},
                                     field: {:iata_country_code, "iata_country_code", "string"},
                                     field: {:iata_code, "iata_code", "string"}
                                   ]}
                              ]},
                           field: {:departure_date, "departure_date", "string"}
                         ]},
                      has_many:
                        {:passengers, "passengers",
                         [
                           field: {:type, "type", "string"},
                           has_many:
                             {:loyalty_programme_accounts, "loyalty_programme_accounts",
                              [
                                field: {:airline_iata_code, "airline_iata_code", "string"},
                                field: {:account_number, "account_number", "string"}
                              ]},
                           field: {:id, "id", "string"},
                           field: {:given_name, "given_name", "string"},
                           field: {:family_name, "family_name", "string"},
                           field: {:age, "age", "integer"}
                         ]},
                      has_many:
                        {:offers, "offers",
                         [
                           field: {:total_emissions_kg, "total_emissions_kg", "string"},
                           field: {:total_currency, "total_currency", "string"},
                           field: {:total_amount, "total_amount", "string"},
                           field: {:tax_currency, "tax_currency", "string"},
                           field: {:tax_amount, "tax_amount", "string"},
                           has_many:
                             {:slices, "slices",
                              [
                                has_many:
                                  {:segments, "segments",
                                   [
                                     has_many:
                                       {:passengers, "passengers",
                                        [
                                          field: {:passenger_id, "passenger_id", "string"},
                                          field: {:fare_basis_code, "fare_basis_code", "string"},
                                          field:
                                            {:cabin_class_marketing_name,
                                             "cabin_class_marketing_name", "string"},
                                          field: {:cabin_class, "cabin_class", "string"},
                                          has_many:
                                            {:baggages, "baggages",
                                             [
                                               field: {:type, "type", "string"},
                                               field: {:quantity, "quantity", "integer"}
                                             ]}
                                        ]},
                                     field: {:origin_terminal, "origin_terminal", "string"},
                                     field: {:time_zone, "time_zone", "string"},
                                     field: {:name, "name", "string"},
                                     field: {:longitude, "longitude", "integer"},
                                     field: {:latitude, "latitude", "integer"},
                                     field: {:id, "id", "string"},
                                     field: {:icao_code, "icao_code", "string"},
                                     field: {:iata_country_code, "iata_country_code", "string"},
                                     field: {:iata_code, "iata_code", "string"},
                                     field: {:city_name, "city_name", "string"},
                                     has_one:
                                       {:city, "city",
                                        [
                                          field: {:name, "name", "string"},
                                          field: {:id, "id", "string"},
                                          field:
                                            {:iata_country_code, "iata_country_code", "string"},
                                          field: {:iata_code, "iata_code", "string"}
                                        ]},
                                     field:
                                       {:operating_carrier_flight_number,
                                        "operating_carrier_flight_number", "string"},
                                     field: {:name, "name", "string"},
                                     field: {:id, "id", "string"},
                                     field: {:iata_code, "iata_code", "string"},
                                     field:
                                       {:marketing_carrier_flight_number,
                                        "marketing_carrier_flight_number", "string"},
                                     field: {:name, "name", "string"},
                                     field: {:id, "id", "string"},
                                     field: {:iata_code, "iata_code", "string"},
                                     field: {:id, "id", "string"},
                                     field: {:duration, "duration", "string"},
                                     field: {:distance, "distance", "string"},
                                     field:
                                       {:destination_terminal, "destination_terminal", "string"},
                                     field: {:time_zone, "time_zone", "string"},
                                     field: {:name, "name", "string"},
                                     field: {:longitude, "longitude", "integer"},
                                     field: {:latitude, "latitude", "integer"},
                                     field: {:id, "id", "string"},
                                     field: {:icao_code, "icao_code", "string"},
                                     field: {:iata_country_code, "iata_country_code", "string"},
                                     field: {:iata_code, "iata_code", "string"},
                                     field: {:city_name, "city_name", "string"},
                                     has_one:
                                       {:city, "city",
                                        [
                                          field: {:name, "name", "string"},
                                          field: {:id, "id", "string"},
                                          field:
                                            {:iata_country_code, "iata_country_code", "string"},
                                          field: {:iata_code, "iata_code", "string"}
                                        ]},
                                     field: {:departing_at, "departing_at", "string"},
                                     field: {:arriving_at, "arriving_at", "string"},
                                     field: {:name, "name", "string"},
                                     field: {:id, "id", "string"},
                                     field: {:iata_code, "iata_code", "string"}
                                   ]},
                                field: {:origin_type, "origin_type", "string"},
                                field: {:type, "type", "string"},
                                field: {:time_zone, "time_zone", "string"},
                                field: {:name, "name", "string"},
                                field: {:longitude, "longitude", "integer"},
                                field: {:latitude, "latitude", "integer"},
                                field: {:id, "id", "string"},
                                field: {:icao_code, "icao_code", "string"},
                                field: {:iata_country_code, "iata_country_code", "string"},
                                field: {:iata_code, "iata_code", "string"},
                                field: {:iata_city_code, "iata_city_code", "string"},
                                field: {:city_name, "city_name", "string"},
                                field: {:name, "name", "string"},
                                field: {:id, "id", "string"},
                                field: {:iata_country_code, "iata_country_code", "string"},
                                field: {:iata_code, "iata_code", "string"},
                                has_many:
                                  {:airports, "airports",
                                   [
                                     field: {:time_zone, "time_zone", "string"},
                                     field: {:name, "name", "string"},
                                     field: {:longitude, "longitude", "integer"},
                                     field: {:latitude, "latitude", "integer"},
                                     field: {:id, "id", "string"},
                                     field: {:icao_code, "icao_code", "string"},
                                     field: {:iata_country_code, "iata_country_code", "string"},
                                     field: {:iata_code, "iata_code", "string"},
                                     field: {:city_name, "city_name", "string"},
                                     has_one:
                                       {:city, "city",
                                        [
                                          field: {:name, "name", "string"},
                                          field: {:id, "id", "string"},
                                          field:
                                            {:iata_country_code, "iata_country_code", "string"},
                                          field: {:iata_code, "iata_code", "string"}
                                        ]}
                                   ]},
                                field: {:id, "id", "string"},
                                field: {:fare_brand_name, "fare_brand_name", "string"},
                                field: {:duration, "duration", "string"},
                                field: {:destination_type, "destination_type", "string"},
                                field: {:type, "type", "string"},
                                field: {:time_zone, "time_zone", "string"},
                                field: {:name, "name", "string"},
                                field: {:longitude, "longitude", "integer"},
                                field: {:latitude, "latitude", "integer"},
                                field: {:id, "id", "string"},
                                field: {:icao_code, "icao_code", "string"},
                                field: {:iata_country_code, "iata_country_code", "string"},
                                field: {:iata_code, "iata_code", "string"},
                                field: {:iata_city_code, "iata_city_code", "string"},
                                field: {:city_name, "city_name", "string"},
                                field: {:name, "name", "string"},
                                field: {:id, "id", "string"},
                                field: {:iata_country_code, "iata_country_code", "string"},
                                field: {:iata_code, "iata_code", "string"},
                                has_many:
                                  {:airports, "airports",
                                   [
                                     field: {:time_zone, "time_zone", "string"},
                                     field: {:name, "name", "string"},
                                     field: {:longitude, "longitude", "integer"},
                                     field: {:latitude, "latitude", "integer"},
                                     field: {:id, "id", "string"},
                                     field: {:icao_code, "icao_code", "string"},
                                     field: {:iata_country_code, "iata_country_code", "string"},
                                     field: {:iata_code, "iata_code", "string"},
                                     field: {:city_name, "city_name", "string"},
                                     has_one:
                                       {:city, "city",
                                        [
                                          field: {:name, "name", "string"},
                                          field: {:id, "id", "string"},
                                          field:
                                            {:iata_country_code, "iata_country_code", "string"},
                                          field: {:iata_code, "iata_code", "string"}
                                        ]}
                                   ]},
                                has_one:
                                  {:conditions, "conditions",
                                   [
                                     has_one:
                                       {:change_before_departure, "change_before_departure",
                                        [
                                          field:
                                            {:penalty_currency, "penalty_currency", "string"},
                                          field: {:penalty_amount, "penalty_amount", "string"},
                                          field: {:allowed, "allowed", "boolean"}
                                        ]}
                                   ]}
                              ]},
                           field:
                             {:requires_instant_payment, "requires_instant_payment", "boolean"},
                           field:
                             {:price_guarantee_expires_at, "price_guarantee_expires_at", "string"},
                           field: {:payment_required_by, "payment_required_by", "string"},
                           has_many:
                             {:passengers, "passengers",
                              [
                                field: {:type, "type", "string"},
                                has_many:
                                  {:loyalty_programme_accounts, "loyalty_programme_accounts",
                                   [
                                     field: {:airline_iata_code, "airline_iata_code", "string"},
                                     field: {:account_number, "account_number", "string"}
                                   ]},
                                field: {:id, "id", "string"},
                                field: {:given_name, "given_name", "string"},
                                field: {:family_name, "family_name", "string"},
                                field: {:age, "age", "integer"}
                              ]},
                           field:
                             {:passenger_identity_documents_required,
                              "passenger_identity_documents_required", "boolean"},
                           field: {:name, "name", "string"},
                           field: {:id, "id", "string"},
                           field: {:iata_code, "iata_code", "string"},
                           field: {:live_mode, "live_mode", "boolean"},
                           field: {:id, "id", "string"},
                           field: {:expires_at, "expires_at", "string"},
                           field: {:created_at, "created_at", "string"},
                           has_one:
                             {:conditions, "conditions",
                              [
                                has_one:
                                  {:refund_before_departure, "refund_before_departure",
                                   [
                                     field: {:penalty_currency, "penalty_currency", "string"},
                                     field: {:penalty_amount, "penalty_amount", "string"},
                                     field: {:allowed, "allowed", "boolean"}
                                   ]},
                                has_one:
                                  {:change_before_departure, "change_before_departure",
                                   [
                                     field: {:penalty_currency, "penalty_currency", "string"},
                                     field: {:penalty_amount, "penalty_amount", "string"},
                                     field: {:allowed, "allowed", "boolean"}
                                   ]}
                              ]},
                           field: {:base_currency, "base_currency", "string"},
                           field: {:base_amount, "base_amount", "string"},
                           has_many:
                             {:allowed_passenger_identity_document_types,
                              "allowed_passenger_identity_document_types", ["passport"]}
                         ]},
                      field: {:live_mode, "live_mode", "boolean"},
                      field: {:id, "id", "string"},
                      field: {:created_at, "created_at", "string"},
                      field: {:cabin_class, "cabin_class", "string"}
                    ]}
               ]
             }
    end
  end
end
