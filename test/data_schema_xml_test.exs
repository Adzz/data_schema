defmodule DataSchemaXmlTest do
  use ExUnit.Case

  use ExUnit.Case, async: true

  defmodule Cheese do
    require DataSchema

    DataSchema.data_schema(
      [
        field: {:mouldy?, "./@Mouldy", fn "true" -> true end}
      ],
      XpathAccessor
    )

    def cast(xmerl), do: DataSchema.to_struct!(xmerl, __MODULE__)
  end

  defmodule Salad do
    require DataSchema

    DataSchema.data_schema(
      [field: {:name, "./@Name", & &1}, list_of: {:cheese_slices, "./Cheese", Cheese}],
      XpathAccessor
    )

    def cast(xmerl), do: DataSchema.to_struct!(xmerl, __MODULE__)
  end

  defmodule Sauce do
    require DataSchema

    DataSchema.data_schema([field: {:name, "./@Name", & &1}], XpathAccessor)
  end

  defmodule SteamedHam do
    require DataSchema
    @datetime_fields %{date: "./ReadyDate/text()", time: "./ReadyTime/text()"}
    DataSchema.data_schema(
      [
        field: {:type, "./Type/text()", &String.upcase/1},
        list_of: {:salads, "./Salads/Salad", Salad},
        has_one: {:sauce, "./Sauce", Sauce},
        aggregate: {:ready_datetime, @datetime_fields, &__MODULE__.datetime/1}
      ],
      XpathAccessor
    )

    def datetime(%{date: date, time: time}) do
      date = Date.from_iso8601!(date)
      time = Time.from_iso8601!(time)
      DateTime.new!(date, time)
    end
  end

  defmodule OptionalTest do
    require DataSchema

    DataSchema.data_schema(
      [
        field: {:type, "./Type/text()", &String.upcase/1, optional?: true},
        list_of: {:salads, "./Salads/Salad", Salad, optional?: true},
        has_one: {:sauce, "./Sauce", Sauce, optional?: true}
      ],
      XpathAccessor
    )
  end

  test "Fields are required by default" do
    error_message =
      "the following keys must also be given when building " <>
        "struct DataSchemaXmlTest.SteamedHam: [:ready_datetime, :sauce, :salads, :type]"

    assert_raise(ArgumentError, error_message, fn ->
      # Not providing all required keys is a compiler error so we quote it otherwise we'll
      # get a compiler error before the test runs. But strangely when we compile the
      # quoted code we end up with an ArgumentError. But we test the same thing essentially.
      ast =
        quote do
          %SteamedHam{}
        end

      Code.compile_quoted(ast)
    end)
  end

  test "Fields can be marked as optional" do
    # This is not an error, effectively
    assert %OptionalTest{}
  end

  test "a private function is added which returns the map accessor" do
    assert SteamedHam.__data_accessor() == XpathAccessor
  end

  test "fields are added as a secret fn" do
    assert SteamedHam.__data_schema_fields() == [
             field: {:type, "./Type/text()", &String.upcase/1},
             list_of: {:salads, "./Salads/Salad", DataSchemaXmlTest.Salad},
             has_one: {:sauce, "./Sauce", DataSchemaXmlTest.Sauce},
             aggregate: {
               :ready_datetime,
               %{date: "./ReadyDate/text()", time: "./ReadyTime/text()"},
               &DataSchemaXmlTest.SteamedHam.datetime/1
             }
           ]
  end

  describe "to_struct!/2" do
    test "casts a :field" do
      burger = DataSchema.to_struct!(xml(), SteamedHam)

      assert burger.__struct__ == DataSchemaXmlTest.SteamedHam
      assert burger.type == "MEDIUM RARE"
    end

    test "casts all list_of fields" do
      burger = DataSchema.to_struct!(xml(), SteamedHam)

      assert burger.__struct__ == DataSchemaXmlTest.SteamedHam

      assert burger.salads == [
               %DataSchemaXmlTest.Salad{
                 cheese_slices: [%DataSchemaXmlTest.Cheese{mouldy?: true}],
                 name: "ceasar"
               }
             ]
    end

    test "casts an embed_one field" do
      burger = DataSchema.to_struct!(xml(), SteamedHam)

      assert burger.__struct__ == DataSchemaXmlTest.SteamedHam

      assert burger.sauce == %DataSchemaXmlTest.Sauce{name: "burger sauce"}
    end
  end

  defp xml do
    """
    <SteamedHam>
      <ReadyDate>2021-09-11</ReadyDate>
      <ReadyTime>15:50:07,123Z</ReadyTime>
      <Sauce Name="burger sauce">spicy</Sauce>
      <Type>medium rare</Type>
      <Salads>
        <Salad Name="ceasar">
          <Cheese Mouldy="true">Blue</Cheese>
        </Salad>
      </Salads>
    </SteamedHam>
    """
  end
end
