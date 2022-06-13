defmodule DataSchema.ToRuntimeSchemaTest do
  use ExUnit.Case, async: true

  defmodule NotASchema do
  end

  describe "to_runtime_schema/2" do
    test "raises an error if the module is not a data schema" do
      assert_raise(
        RuntimeError,
        "Provided schema is not a valid DataSchema: DataSchema.ToRuntimeSchemaTest.NotASchema",
        fn -> DataSchema.to_runtime_schema(NotASchema) end
      )
    end

    test "fields and list_of stay as they are" do
      # Schemas in test/support/test_schemas.ex

      assert DataSchema.to_runtime_schema(A) == [
               {:field, {:a, "a", String}},
               {:list_of, {:b, "b", String}}
             ]
    end

    test "list_of and field with opts stay the same" do
      assert DataSchema.to_runtime_schema(AOpts) == [
               field: {:a, "a", String, [optional?: true]},
               list_of: {:b, "b", String, [optional?: true]}
             ]
    end

    test "has_one has_many get expanded" do
      assert DataSchema.to_runtime_schema(AHas) == [
               has_one:
                 {:d, "d",
                  {D,
                   [
                     field: {:a, "a", String},
                     list_of: {:b, "b", String},
                     has_one:
                       {:c, "c", {C, [field: {:a, "a", String}, list_of: {:b, "b", String}]}}
                   ]}},
               has_many: {:c, "c", {C, [field: {:a, "a", String}, list_of: {:b, "b", String}]}}
             ]
    end

    test "has_one has_many opts get expanded" do
      assert DataSchema.to_runtime_schema(AHasOpts) == [
               has_one: {
                 :d,
                 "d",
                 {
                   DOpts,
                   [
                     field: {:a, "a", String},
                     list_of: {:b, "b", String},
                     has_one:
                       {:c, "c", {COpts, [field: {:a, "a", String}, list_of: {:b, "b", String}]}}
                   ]
                 }
               },
               has_many:
                 {:c, "c", {COpts, [field: {:a, "a", String}, list_of: {:b, "b", String}]}}
             ]
    end
  end
end
