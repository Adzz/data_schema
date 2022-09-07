defmodule DefaultValueOptionTest do
  use ExUnit.Case, async: true

  describe "default_value" do
    test "default value is used if a field is optional and empty." do
      schema = [
        field:
          {:a, "a", &{:ok, &1},
           empty_values: [nil], default: fn -> :not_there end, optional?: true}
      ]

      input = %{}
      result = DataSchema.to_struct(input, %{}, schema, DataSchema.MapAccessor)
      assert result == {:ok, %{a: :not_there}}
    end

    test "default value is used for list_of when optional and empty" do
      schema = [
        list_of:
          {:a, "a", &{:ok, &1},
           empty_values: [nil], default: fn -> :not_there end, optional?: true}
      ]

      input = %{}
      result = DataSchema.to_struct(input, %{}, schema, DataSchema.MapAccessor)
      assert result == {:ok, %{a: :not_there}}
    end

    test "default value is used for has_many when optional and empty" do
      schema = [
        has_many:
          {:a, "a", {%{}, [field: {:b, "b", &{:ok, &1}}]},
           empty_values: [nil], default: fn -> :not_there end, optional?: true}
      ]

      input = %{}
      result = DataSchema.to_struct(input, %{}, schema, DataSchema.MapAccessor)
      assert result == {:ok, %{a: :not_there}}
    end

    test "default value is used for has_one when optional and empty" do
      schema = [
        has_one:
          {:a, "a", {%{}, [field: {:b, "b", &{:ok, &1}}]},
           empty_values: [nil], default: fn -> :not_there end, optional?: true}
      ]

      input = %{}
      result = DataSchema.to_struct(input, %{}, schema, DataSchema.MapAccessor)
      assert result == {:ok, %{a: :not_there}}
    end

    test "default value is used for aggregate when optional and empty" do
      # Aggregates are a bit weird because the "empty" value is never null...
      # I guess it should only respect the fields but technically you can provide
      # the same options to it so like you could have an "empty" value of %{a: nil, b: nil}
      # and the aggregate function wont be called.
      schema = [
        aggregate:
          {:agg, [field: {:a, "b", &{:ok, &1}, optional?: true}], &{:ok, &1},
           empty_values: [%{a: nil}], default: fn -> :not_there end, optional?: true}
      ]

      input = %{}
      result = DataSchema.to_struct(input, %{}, schema, DataSchema.MapAccessor)
      assert result == {:ok, %{agg: :not_there}}

      # This is when the field we are aggregating is empty, then we
      aggregates = [
        field:
          {:a, "b", &{:ok, &1},
           empty_values: [nil], default: fn -> :not_there end, optional?: true}
      ]

      schema = [aggregate: {:agg, aggregates, &{:ok, &1}}]

      input = %{}
      result = DataSchema.to_struct(input, %{}, schema, DataSchema.MapAccessor)
      assert result == {:ok, %{agg: %{a: :not_there}}}
    end
  end
end
