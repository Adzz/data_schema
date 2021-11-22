defmodule DataSchema.FieldTest do
  use ExUnit.Case, async: true

  @moduledoc """
  All kinds of tests for the :field field type.
  """

  describe ":field type to_struct/2" do
    test "non null field that returns null from the data accessor errors." do
      defmodule FieldErr do
        import DataSchema
        data_schema(field: {:foo, "foo", fn _ -> {:ok, nil} end})
      end

      input = %{"foo" => nil}

      assert DataSchema.to_struct(input, FieldErr) ==
               {:error,
                %DataSchema.Errors{
                  errors: [foo: "Field was marked as not null but was found to be null."]
                }}

      input = %{}

      assert DataSchema.to_struct(input, FieldErr) ==
               {:error,
                %DataSchema.Errors{
                  errors: [foo: "Field was marked as not null but was found to be null."]
                }}
    end

    test "nested field that returns null returns a nested error." do
      defmodule FieldEr do
        import DataSchema, only: [data_schema: 1]
        data_schema(field: {:foo, "foo", fn _ -> {:ok, nil} end})
      end

      defmodule AggErr do
        import DataSchema, only: [data_schema: 1]
        data_schema(aggregate: {:agg, FieldEr, fn x -> {:ok, x} end})
      end

      input = %{"foo" => 1}

      assert DataSchema.to_struct(input, AggErr) ==
               {:error,
                %DataSchema.Errors{
                  errors: [
                    agg: %DataSchema.Errors{
                      errors: [foo: "Field was marked as not null but was found to be null."]
                    }
                  ]
                }}
    end
  end
end
