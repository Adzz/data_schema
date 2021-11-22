defmodule DataSchema.AggregateTest do
  use ExUnit.Case, async: true

  @moduledoc """
  All kinds of tests for the :field field type.
  """

  describe ":aggregate type to_struct/2" do
    test "non null field that returns null from the data accessor errors." do
      defmodule AggErr do
        import DataSchema, only: [data_schema: 1]

        @fields [
          field: {:foo, "foo", &__MODULE__.null/1}
        ]
        data_schema(aggregate: {:agg, @fields, fn _ -> {:ok, nil} end})

        def null(_), do: {:ok, nil}
      end

      input = %{foo: nil}

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
