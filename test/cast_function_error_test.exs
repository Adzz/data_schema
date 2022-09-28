defmodule DataSchema.CastFunctionErrorTest do
  use ExUnit.Case, async: true
  alias DataSchema.CastFunctionError

  describe "error_message/1" do
    test "when path has no modules in it (ie runtime schema)" do
      error = %DataSchema.CastFunctionError{
        casted_value: "borked",
        # There are a lot of permutations here...
        leaf_field: {:field, {:a, "a", StringType}},
        path: [:a, :b, :c],
        wrapped_error: %RuntimeError{},
        stacktrace_of_wrapped_error: dummy_stacktrace()
      }

      message = CastFunctionError.error_message(error)

      assert message == """


             Unexpected error when casting value "borked"
             for field :c in this part of the schema:

             field: {:a, "a", StringType},

             Full path to field was:

                   Field  :c
             Under Field  :b
             Under Field  :a

             The casting function raised the following error:

             ** (RuntimeError) runtime error
             """
    end

    test "compile time schemas" do
      error = %DataSchema.CastFunctionError{
        casted_value: "borked",
        # There are a lot of permutations here...
        leaf_field: {:field, {:a, "a", StringType}},
        path: [{ASchema, :a}, {BSchema, :b}, {CSchema, :c}],
        wrapped_error: %RuntimeError{},
        stacktrace_of_wrapped_error: dummy_stacktrace()
      }

      message = CastFunctionError.error_message(error)

      assert message == """


             Unexpected error when casting value "borked"
             for field :c in schema CSchema

             Full path to field was:

                   Field  :c in CSchema
             Under Field  :b in BSchema
             Under Field  :a in ASchema

             The casting function raised the following error:

             ** (RuntimeError) runtime error
             """
    end

    test "mix of runtime and compile time schemas - aggregate" do
      error = %DataSchema.CastFunctionError{
        casted_value: "borked",
        leaf_field: {:aggregate, {:post_datetime, [field: {:a, "a", StringType}], AggType}},
        path: [:a, {BSchema, :b}, :c],
        wrapped_error: %RuntimeError{},
        stacktrace_of_wrapped_error: dummy_stacktrace()
      }

      message = CastFunctionError.error_message(error)

      assert message == """


             Unexpected error when casting value "borked"
             for field :c in this part of the schema:

             @aggregate_fields [
               field: {:a, "a", StringType},
             ]
             aggregate: {:post_datetime, @aggregate_fields, AggType},


             Full path to field was:

                   Field  :c
             Under Field  :b in BSchema
             Under Field  :a

             The casting function raised the following error:

             ** (RuntimeError) runtime error
             """
    end
  end

  defp dummy_stacktrace() do
    [
      {DataSchema.String, :cast, 1,
       [file: 'test/support/string.ex', line: 9, error_info: %{module: Exception}]},
      {DataSchema, :call_cast_fn, 3, [file: 'lib/data_schema.ex', line: 1082]}
    ]
  end
end
