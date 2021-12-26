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
                "description": "A single aircraft resource",
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

    assert DataSchema.schemas_from_open_api_json(json) == %{
             "GetAircraftById" => [
               {:iata_code, "iata_code", "string"},
               {:id, "id", "string"},
               {:name, "name", "string"}
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
                "description": "A paginated list of aircraft",
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
                          }
                        },
                        "meta": {
                          "title": "Pagination Meta",
                          "type": "object",
                          "properties": {
                            "after": {
                              "type": "string",
                              "nullable": true,
                              "description": "`after` is a cursor used to identify the next page of results. If `meta.after` is null, then there are no more results to see.",
                              "example": "g2wAAAACbQAAABBBZXJvbWlzdC1LaGFya2l2bQAAAB="
                            },
                            "before": {
                              "type": "string",
                              "nullable": true,
                              "description": "`before` is a cursor used to identify the previous page of results.",
                              "example": null
                            },
                            "limit": {
                              "type": "integer",
                              "description": "The limit of entries returned on each page.",
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
    assert DataSchema.schemas_from_open_api_json(json) == %{
             "GetAircraft" => [
               {:iata_code, "iata_code", "string"},
               {:id, "id", "string"},
               {:name, "name", "string"}
             ]
           }
  end
end
