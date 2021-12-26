defmodule DataSchema.RuntimeSchemaTest do
  use ExUnit.Case

  @moduledoc """
  """

  defmodule Route do
    defstruct [:length]
  end

  defmodule Result do
    defstruct [:winner?]
  end

  defmodule Y do
    defstruct [:y]
  end

  defmodule X do
    defstruct [:x]
  end

  defmodule Run do
    defstruct [:bpm, :times, :stats, :routes, :result]
  end

  describe "Runtime schema into a struct" do
    test "when there are no errors" do
      input = %{
        "wut" => "great",
        "beats_per_min" => 10,
        "times" => [1, 2, 3],
        "items" => [1400],
        "stats" => %{"wut" => "YAY"},
        "xs" => [%{"x" => "1XXX"}, %{"x" => "2XXX"}],
        "why" => %{"y" => "WHY?!"},
        "result" => %{"won" => true},
        "routes" => [%{"length" => 1}]
      }

      stats_fields = [
        field: {:bpm, "beats_per_min", &{:ok, &1}},
        list_of: {:items, "times", &{:ok, &1}},
        aggregate: {:stats, [field: {:ok, "wut", &{:ok, &1}}], &{:ok, &1}},
        has_many: {:xs, "xs", {X, [field: {:x, "x", &{:ok, &1}}]}},
        has_one: {:why, "why", {Y, [field: {:y, "y", &{:ok, &1}}]}}
      ]

      route_fields = [field: {:length, "length", &{:ok, &1}}]
      result_fields = [field: {:winner?, "won", &{:ok, &1}}]

      fields = [
        field: {:bpm, "beats_per_min", &{:ok, &1}},
        list_of: {:times, "times", &{:ok, &1}},
        aggregate: {:stats, stats_fields, &{:ok, &1}},
        has_many: {:routes, "routes", {Route, route_fields}},
        has_one: {:result, "result", {Result, result_fields}}
      ]

      {:ok, result} = DataSchema.to_struct(input, %Run{}, fields, DataSchema.MapAccessor)

      assert result == %Run{
               bpm: 10,
               result: %Result{winner?: true},
               routes: [%Route{length: 1}],
               stats: %{
                 bpm: 10,
                 items: [1, 2, 3],
                 stats: %{ok: "great"},
                 why: %Y{y: "WHY?!"},
                 xs: [%X{x: "1XXX"}, %X{x: "2XXX"}]
               },
               times: [1, 2, 3]
             }
    end
  end
end
