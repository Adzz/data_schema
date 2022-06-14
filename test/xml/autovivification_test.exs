defmodule DataSchema.AutovivificationTest do
  use ExUnit.Case, async: true

  describe "really_put_in/2" do
    test "we add a key to a map" do
      assert DataSchema.XML.Saxy.really_put_in(["A"], %{}) == %{"A" => %{}}
    end

    test "text field" do
      path = ["A", "text()"]
      assert DataSchema.XML.Saxy.really_put_in(path, %{}) == %{"A" => %{text: true}}
    end

    test "attr field" do
      path = ["A", "@attr"]
      assert DataSchema.XML.Saxy.really_put_in(path, %{}) == %{"A" => %{{:attr, "attr"} => true}}
    end

    test "one level nesting" do
      path = ["A", "B", "C"]
      assert DataSchema.XML.Saxy.really_put_in(path, %{}) == %{"A" => %{"B" => %{"C" => %{}}}}
    end

    test "kitchen sink" do
      path = [
        "SOAP-ENV:Envelope",
        "SOAP-ENV:Body",
        "ns1:XXTransactionResponse",
        "RSP",
        "AirShoppingRS",
        "ShoppingResponseID",
        "ResponseID",
        "text()"
      ]

      assert DataSchema.XML.Saxy.really_put_in(path, %{}) == %{
               "SOAP-ENV:Envelope" => %{
                 "SOAP-ENV:Body" => %{
                   "ns1:XXTransactionResponse" => %{
                     "RSP" => %{
                       "AirShoppingRS" => %{
                         "ShoppingResponseID" => %{"ResponseID" => %{text: true}}
                       }
                     }
                   }
                 }
               }
             }
    end
  end

  describe "saxy_schema_from_runtime_schema/1" do
    test "simple" do
      assert DataSchema.XML.Saxy.saxy_schema_from_runtime_schema(A) == %{"a" => %{}, "b" => %{}}
    end

    test "simple opts" do
      assert DataSchema.XML.Saxy.saxy_schema_from_runtime_schema(AOpts) == %{
               "a" => %{},
               "b" => %{}
             }
    end

    test "with children AHasOpts" do
      assert DataSchema.XML.Saxy.saxy_schema_from_runtime_schema(AHasOpts) == %{
               "c" => %{"a" => %{}, "b" => %{}},
               "d" => %{"a" => %{}, "b" => %{}, "c" => %{"a" => %{}, "b" => %{}}}
             }
    end

    test "runtime" do
      fields = [
        field:
          {:response_sid,
           [
             "SOAP-ENV:Envelope",
             "SOAP-ENV:Body",
             "ns1:XXTransactionResponse",
             "RSP",
             "AirShoppingRS",
             "ShoppingResponseID",
             "ResponseID",
             "text()"
           ], StringType},
        has_many:
          {:warnings,
           [
             "SOAP-ENV:Envelope",
             "SOAP-ENV:Body",
             "ns1:XXTransactionResponse",
             "RSP",
             "AirShoppingRS",
             "Warnings",
             "Warning"
           ],
           {Warning,
            [
              field: {:code, ["Warning", "@Code"], StringType, [optional?: true]},
              field: {:owner, ["Warning", "@Owner"], StringType, [optional?: true]},
              field: {:type, ["Warning", "@Type"], StringType, [optional?: true]},
              field: {:title, ["Warning", "@ShortText"], StringType, [optional?: true]},
              field: {:description, ["Warning", "text()"], StringType, [optional?: true]}
            ]}},
        has_many:
          {:errors,
           [
             "SOAP-ENV:Envelope",
             "SOAP-ENV:Body",
             "ns1:XXTransactionResponse",
             "RSP",
             "AirShoppingRS",
             "Errors",
             "Error"
           ],
           {Error,
            [
              field: {:code, ["Error", "@Code"], StringType, [optional?: true]},
              field: {:sid, ["Error", "@Owner"], StringType, [optional?: true]},
              field: {:status, ["Error", "@Status"], StringType, [optional?: true]},
              field: {:type, ["Error", "@Type"], StringType, [optional?: true]},
              field: {:title, ["Error", "@ShortText"], StringType, [optional?: true]},
              field: {:description, ["Error", "text()"], StringType, [optional?: true]}
            ]}, [optional?: true]}
      ]

      assert DataSchema.XML.Saxy.saxy_schema_from_runtime_schema(fields) == []
    end
  end
end
