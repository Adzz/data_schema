defmodule DataSchema.AggregateTest do
  use ExUnit.Case, async: true

  @moduledoc """
  All kinds of tests for the :field field type.
  """
  defmodule AggErr do
    import DataSchema, only: [data_schema: 1]

    @fields [
      field: {:foo, "foo", &__MODULE__.null/1}
    ]
    data_schema(aggregate: {:agg, @fields, fn _ -> {:ok, nil} end})

    def null(_), do: {:ok, nil}
  end

  defmodule AggListOf do
    import DataSchema, only: [data_schema: 1]

    @fields [
      list_of: {:values, "foo", &__MODULE__.to_int/1}
    ]
    data_schema(aggregate: {:agg, @fields, fn %{values: values} -> {:ok, Enum.sum(values)} end})

    def to_int(x), do: {:ok, String.to_integer(x)}
  end

  defmodule AggErrSchema do
    import DataSchema, only: [data_schema: 1]

    data_schema(aggregate: {:agg, AggListOf, &{:ok, &1}})

    def null(_), do: {:ok, nil}
  end

  describe ":aggregate type to_struct/2" do
    test "non null field that returns null from the data accessor errors." do
      input = %{foo: nil}

      assert DataSchema.to_struct(input, AggErr) ==
               {:error,
                %DataSchema.Errors{
                  errors: [
                    agg: %DataSchema.Errors{
                      errors: [
                        foo: "Field was required but value supplied is considered empty"
                      ]
                    }
                  ]
                }}
    end

    test "aggregate fields can be nested schemas" do
      input = %{"foo" => ["1", "2", "3"]}

      assert DataSchema.to_struct(input, AggErrSchema) ==
               {:ok,
                %DataSchema.AggregateTest.AggErrSchema{
                  agg: %DataSchema.AggregateTest.AggListOf{agg: 6}
                }}
    end

    test "when aggregate is an inline list_of" do
      input = %{"foo" => ["1", "2", "3"]}

      assert DataSchema.to_struct(input, AggListOf) ==
               {:ok, %DataSchema.AggregateTest.AggListOf{agg: 6}}
    end
  end
end
