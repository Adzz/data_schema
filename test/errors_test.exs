defmodule DataSchema.ErrorsTest do
  use ExUnit.Case, async: true
  doctest DataSchema.Errors

  defmodule Author do
    import DataSchema, only: [data_schema: 1]
    data_schema(field: {:name, "name", fn _ -> :error end})
  end

  defmodule Comment do
    import DataSchema, only: [data_schema: 1]
    data_schema(has_one: {:author, "author", Author})
  end

  defmodule BlagPost do
    import DataSchema, only: [data_schema: 1]

    data_schema(
      field: {:content, "content", &{:ok, to_string(&1)}},
      has_many: {:comments, "comments", Comment}
    )
  end

  describe "to_error_tuple" do
    test "we convert an error to an error tuple" do
      error = %DataSchema.Errors{
        errors: [
          comments: %DataSchema.Errors{
            errors: [
              author: %DataSchema.Errors{
                errors: [name: "There was an error!"]
              }
            ]
          }
        ]
      }

      assert DataSchema.Errors.to_error_tuple(error) ==
               {:error, {[:comments, :author, :name], "There was an error!"}}
    end
  end

  describe "flatten_errors" do
    test "we flatten the error path" do
      error = %DataSchema.Errors{
        errors: [
          comments: %DataSchema.Errors{
            errors: [
              author: %DataSchema.Errors{
                errors: [name: "There was an error!"]
              }
            ]
          }
        ]
      }

      assert DataSchema.Errors.flatten_errors(error) ==
               {[:comments, :author, :name], "There was an error!"}
    end
  end

  test "has_many has_one" do
    input = %{
      "content" => "This is a blog post",
      "comments" => [
        %{"author" => %{"name" => "Ted"}},
        %{"author" => %{"name" => "Danson"}}
      ]
    }

    assert DataSchema.to_struct(input, BlagPost) ==
             {
               :error,
               %DataSchema.Errors{
                 errors: [
                   comments: %DataSchema.Errors{
                     errors: [author: %DataSchema.Errors{errors: [name: "There was an error!"]}]
                   }
                 ]
               }
             }
  end

  describe "runtime schema" do
    test "" do
    end
  end

  test "has_many" do
    defmodule Cheeese do
      require DataSchema

      DataSchema.data_schema(field: {:mouldy?, "mouldy", fn _ -> :error end})
    end

    defmodule Saladd do
      require DataSchema

      DataSchema.data_schema(
        field: {:name, "name", &{:ok, &1}},
        has_many: {:cheese_slices, "cheese", Cheeese}
      )
    end

    input = %{
      "name" => "ted",
      "cheese" => [%{"mouldy" => 1}]
    }

    assert DataSchema.to_struct(input, Saladd) ==
             {:error,
              %DataSchema.Errors{
                errors: [
                  cheese_slices: %DataSchema.Errors{errors: [mouldy?: "There was an error!"]}
                ]
              }}
  end

  describe "aggregate" do
    test "default error" do
      defmodule FieldEr do
        import DataSchema, only: [data_schema: 1]
        data_schema(field: {:foo, "foo", fn _ -> :error end})
      end

      defmodule AggErr do
        import DataSchema, only: [data_schema: 1]
        data_schema(aggregate: {:agg, FieldEr, fn x -> {:ok, x} end})
      end

      input = %{"foo" => 1}

      assert DataSchema.to_struct(input, AggErr) ==
               {:error,
                %DataSchema.Errors{
                  errors: [agg: %DataSchema.Errors{errors: [foo: "There was an error!"]}]
                }}
    end

    test "named error" do
      defmodule FieldErr do
        import DataSchema, only: [data_schema: 1]
        data_schema(field: {:foo, "foo", fn _ -> {:error, "nope"} end})
      end

      defmodule AggEr do
        import DataSchema, only: [data_schema: 1]
        data_schema(aggregate: {:agg, FieldErr, fn x -> {:ok, x} end})
      end

      input = %{"foo" => 1}

      assert DataSchema.to_struct(input, AggEr) ==
               {:error,
                %DataSchema.Errors{
                  errors: [agg: %DataSchema.Errors{errors: [foo: "nope"]}]
                }}
    end
  end

  test "list_of" do
    defmodule Thing do
      defstruct [:things]
    end

    schema = [
      list_of: {:things, "things", fn _ -> :error end}
    ]

    input = %{"things" => [%{"thing" => 1}, %{"thing" => 1}]}

    assert DataSchema.to_struct(input, Thing, schema, DataSchema.MapAccessor) ==
             {:error, %DataSchema.Errors{errors: [things: "There was an error!"]}}
  end
end
