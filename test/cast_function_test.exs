defmodule DataSchema.CastFunctionTest do
  use ExUnit.Case, async: true

  describe "We raise a nice error when the cast function returns something it shoudln't" do
    test "field" do
      input = %{"beats_per_min" => 10}
      fields = [field: {:bpm, "beats_per_min", & &1}]

      message =
        "Casting error for field bpm, cast function should return one of the following:\n\n  {:ok, any()} | :error | {:error, any()}\n\nCast function returned 10\n"

      assert_raise(DataSchema.InvalidCastFunction, message, fn ->
        DataSchema.to_struct(input, %{}, fields, DataSchema.MapAccessor)
      end)
    end

    test "has_one" do
      input = %{"result" => %{"won" => true}}
      result_fields = [field: {:winner?, "won", & &1}]
      fields = [has_one: {:result, "result", {%{}, result_fields}}]

      message =
        "Casting error for field winner?, cast function should return one of the following:\n\n  {:ok, any()} | :error | {:error, any()}\n\nCast function returned true\n"

      assert_raise(DataSchema.InvalidCastFunction, message, fn ->
        DataSchema.to_struct(input, %{}, fields, DataSchema.MapAccessor)
      end)
    end

    test "has_many" do
      input = %{"routes" => [%{"length" => 1}]}
      route_fields = [field: {:length, "length", & &1}]
      fields = [has_many: {:routes, "routes", {%{}, route_fields}}]

      message =
        "Casting error for field length, cast function should return one of the following:\n\n  {:ok, any()} | :error | {:error, any()}\n\nCast function returned 1\n"

      assert_raise(DataSchema.InvalidCastFunction, message, fn ->
        DataSchema.to_struct(input, %{}, fields, DataSchema.MapAccessor)
      end)
    end

    test "aggregate" do
      input = %{"wut" => "YAY"}
      stats_fields = [field: {:wut, "wut", &{:ok, &1}}]
      fields = [aggregate: {:stats, stats_fields, & &1}]

      message =
        "Casting error for field stats, cast function should return one of the following:\n\n  {:ok, any()} | :error | {:error, any()}\n\nCast function returned %{wut: \"YAY\"}\n"

      assert_raise(DataSchema.InvalidCastFunction, message, fn ->
        DataSchema.to_struct(input, %{}, fields, DataSchema.MapAccessor)
      end)
    end

    test "list_of" do
      input = %{"times" => [1, 2, 3]}
      fields = [list_of: {:times, "times", & &1}]

      message =
        "Casting error for field times, cast function should return one of the following:\n\n  {:ok, any()} | :error | {:error, any()}\n\nCast function returned 1\n"

      assert_raise(DataSchema.InvalidCastFunction, message, fn ->
        DataSchema.to_struct(input, %{}, fields, DataSchema.MapAccessor)
      end)
    end
  end
end
