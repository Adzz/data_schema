defmodule DataSchemaTest do
  use ExUnit.Case, async: true
  doctest DataSchema

  def to_stringg(x), do: {:ok, to_string(x)}
  def comments(x), do: {:ok, x["text"]}

  defmodule DraftPost do
    import DataSchema, only: [data_schema: 1]
    data_schema(field: {:content, "content", &DataSchemaTest.to_stringg/1})
  end

  defmodule Comment do
    import DataSchema, only: [data_schema: 1]
    data_schema(field: {:text, "text", &DataSchemaTest.to_stringg/1})
  end

  defmodule BlogPost do
    import DataSchema, only: [data_schema: 1]

    @mapping [
      field: {:date, "date", {Date, :from_iso8601, []}},
      field: {:time, "time", &Time.from_iso8601/1}
    ]
    data_schema(
      field: {:content, "content", &DataSchemaTest.to_stringg/1},
      has_many: {:comments, "comments", Comment},
      has_one: {:draft, "draft", DraftPost},
      list_of: {:list_of, "comments", &DataSchemaTest.comments/1},
      aggregate: {:post_datetime, @mapping, &BlogPost.to_datetime/1}
    )

    def to_datetime(%{date: date, time: time}) do
      NaiveDateTime.new(date, time)
    end
  end

  defmodule MockAccessor do
    def has_one(_, _), do: nil
  end

  test "when has one returns nil we don't call the cast fn with nil." do
    schema = [
      has_one:
        {:thing, "a", {%{}, [field: {:a, "a", &{:ok, &1}}]}, optional?: true, empty_values: [nil]}
    ]

    input = %{"a" => :empty}
    result = DataSchema.to_struct(input, %{}, schema, MockAccessor)
    assert result == {:ok, %{thing: nil}}
  end

  describe "empty_values option" do
    test "causes errors when making structs declared with values considered as empty (:field)" do
      defmodule Wallet do
        import DataSchema, only: [data_schema: 1]

        data_schema(
          field:
            {:account_number, "account_number", &DataSchemaTest.to_stringg/1,
             [optional?: false, empty_values: ["", nil, :undefined]]}
        )
      end

      assert DataSchema.to_struct(%{account_number: ""}, Wallet) ==
               {:error,
                %DataSchema.Errors{
                  errors: [
                    account_number: "Field was required but value supplied is considered empty"
                  ]
                }}

      assert DataSchema.to_struct(%{account_number: nil}, Wallet) ==
               {:error,
                %DataSchema.Errors{
                  errors: [
                    account_number: "Field was required but value supplied is considered empty"
                  ]
                }}

      assert DataSchema.to_struct(%{account_number: :undefined}, Wallet) ==
               {:error,
                %DataSchema.Errors{
                  errors: [
                    account_number: "Field was required but value supplied is considered empty"
                  ]
                }}
    end

    test "causes errors when making structs declared with values considered as empty (:list_of)" do
      defmodule Something do
        import DataSchema, only: [data_schema: 1]

        data_schema(
          field:
            {:required_array, "required_array", fn v -> {:ok, v} end,
             [optional?: false, empty_values: [[], nil]]}
        )
      end

      assert DataSchema.to_struct(%{required_array: []}, Something) ==
               {:error,
                %DataSchema.Errors{
                  errors: [
                    required_array: "Field was required but value supplied is considered empty"
                  ]
                }}

      assert DataSchema.to_struct(%{required_array: nil}, Something) ==
               {:error,
                %DataSchema.Errors{
                  errors: [
                    required_array: "Field was required but value supplied is considered empty"
                  ]
                }}
    end

    test "causes errors when making structs declared with values considered as empty (:has_many)" do
      defmodule Commentary do
        import DataSchema, only: [data_schema: 1]

        data_schema(
          has_many: {:comments, "comments", Comment, [optional?: false, empty_values: [[], nil]]}
        )
      end

      assert DataSchema.to_struct(%{required_array: []}, Commentary) ==
               {:error,
                %DataSchema.Errors{
                  errors: [
                    comments: "Field was required but value supplied is considered empty"
                  ]
                }}

      assert DataSchema.to_struct(%{comments: nil}, Commentary) ==
               {:error,
                %DataSchema.Errors{
                  errors: [
                    comments: "Field was required but value supplied is considered empty"
                  ]
                }}
    end
  end

  describe "data_schema/1" do
    test "The default MapAccessor is used when no accessor is provided" do
      input = %{
        "content" => "This is a blog post",
        "comments" => [%{"text" => "This is a comment"}, %{"text" => "This is another comment"}],
        "draft" => %{"content" => "This is a draft blog post"},
        "date" => "2021-11-11",
        "time" => "14:00:00",
        "metadata" => %{"rating" => 0}
      }

      {:ok, blog} = DataSchema.to_struct(input, BlogPost)

      assert BlogPost.__data_accessor() == DataSchema.MapAccessor

      assert blog == %DataSchemaTest.BlogPost{
               list_of: ["This is a comment", "This is another comment"],
               comments: [
                 %DataSchemaTest.Comment{text: "This is a comment"},
                 %DataSchemaTest.Comment{text: "This is another comment"}
               ],
               content: "This is a blog post",
               draft: %DataSchemaTest.DraftPost{content: "This is a draft blog post"},
               post_datetime: ~N[2021-11-11 14:00:00]
             }
    end

    test "a private function is added which returns the map accessor" do
      assert BlogPost.__data_accessor() == DataSchema.MapAccessor
    end

    test "if you add a custom data_accessor it is used" do
      defmodule ThingAccessor do
      end

      defmodule Foo do
        import DataSchema, only: [data_schema: 1]
        @data_accessor ThingAccessor
        data_schema(field: {:foo, "foo", &DataSchemaTest.to_stringg/1})
      end

      assert Foo.__data_accessor() == DataSchemaTest.ThingAccessor
    end

    test "fields are added as a secret fn" do
      assert BlogPost.__data_schema_fields() == [
               field: {:content, "content", &DataSchemaTest.to_stringg/1},
               has_many: {:comments, "comments", DataSchemaTest.Comment},
               has_one: {:draft, "draft", DataSchemaTest.DraftPost},
               list_of: {:list_of, "comments", &DataSchemaTest.comments/1},
               aggregate:
                 {:post_datetime,
                  [
                    field: {:date, "date", {Date, :from_iso8601, []}},
                    field: {:time, "time", &Time.from_iso8601/1}
                  ], &DataSchemaTest.BlogPost.to_datetime/1}
             ]
    end

    test "we validate that the struct key must be an atom" do
      message = """
      The provided struct keys must be atoms. See docs for more information:

          data_schema([
            field: {:foo, "foo", &{:ok, &1}}
          #          ^^^
          #   must be an atom!
          ])
      """

      assert_raise(DataSchema.InvalidSchemaError, message, fn ->
        defmodule FieldTest do
          import DataSchema, only: [data_schema: 1]
          data_schema(field: {"foo", "foo", &{:ok, to_string(&1)}})
        end
      end)

      assert_raise(DataSchema.InvalidSchemaError, message, fn ->
        defmodule FieldTest do
          import DataSchema, only: [data_schema: 1]
          data_schema(field: {"foo", "foo", &{:ok, to_string(&1)}, optional?: true})
        end
      end)
    end

    test "we validate the field type" do
      message = """
      Field :not_a_field is not a valid field type.
      Check the docs in DataSchema for more information on how fields should be written.
      The available types are: [:field, :has_one, :has_many, :aggregate, :list_of]
      """

      assert_raise(DataSchema.InvalidSchemaError, message, fn ->
        defmodule FieldTest do
          import DataSchema, only: [data_schema: 1]
          data_schema(not_a_field: {:foo, "foo", &{:ok, to_string(&1)}})
        end
      end)

      assert_raise(DataSchema.InvalidSchemaError, message, fn ->
        defmodule FieldTest do
          import DataSchema, only: [data_schema: 1]
          data_schema(not_a_field: {:foo, "foo", &{:ok, to_string(&1)}, optional?: true})
        end
      end)
    end

    test "we validate aggregate fields if they pass a map" do
      message = """
      An :aggregate field should provide a nested schema to describe the data to be extracted.
      This can be a module of another DataSchema or a list of schema fields:

          defmodule Thing do
            import DataSchema, only: [data_schema: 1]

            @fields [
              field: {:date, "date", &Date.from_iso8601/1},
              field: {:time, "time", &Time.from_iso8601/1}
            ]

            data_schema([
              aggregate: {:datetime, @fields, NaiveDateTime.new(&1.date, &1.time)}
            ])
          end

      Or:

          defmodule Thing do
            import DataSchema, only: [data_schema: 1]

            defmodule DateTime do
              import DataSchema, only: [data_schema: 1]

              data_schema([
                field: {:date, "date", &Date.from_iso8601/1},
                field: {:time, "time", &Time.from_iso8601/1}
              ])
            end

            data_schema([
              aggregate: {:datetime, DateTime, &NaiveDateTime.new(&1.date, &1.time)}
            ])
          end

      Provided schema: %{not_valid: "as_a_thing"}
      """

      assert_raise(DataSchema.InvalidSchemaError, message, fn ->
        defmodule AggTest do
          import DataSchema, only: [data_schema: 1]
          @mapping %{not_valid: "as_a_thing"}
          data_schema(aggregate: {:foo, @mapping, &{:ok, &1}, optional?: true})
        end
      end)

      assert_raise(DataSchema.InvalidSchemaError, message, fn ->
        defmodule AggTest do
          import DataSchema, only: [data_schema: 1]
          @mapping %{not_valid: "as_a_thing"}
          data_schema(aggregate: {:foo, @mapping, &{:ok, &1}})
        end
      end)
    end

    test "we validate has_one provides a schema (and not a fn for example" do
      message = """
      has_one fields require a DataSchema module as their casting function:

          data_schema([
            has_one: {:foo, "path", Foo}
            #                        ^^
            # Should be a DataSchema module
          ])

      Or an inline list of fields like so:

          @foo_fields [
            field: {:bar, "bar", &{:ok, to_string(&1)}}
          ]

          data_schema([
            has_one: {:foo, "path", {%{}, @foo_fields}}
          ])

      Or for an inline struct:

          @foo_fields [
            field: {:bar, "bar", &{:ok, to_string(&1)}}
          ]

          data_schema([
            has_one: {:foo, "path", {SomeStructModule, @foo_fields}}
          ])


      You provided the following as a schema: "ahhh".
      Ensure you haven't used the wrong field type.
      """

      assert_raise(DataSchema.InvalidSchemaError, message, fn ->
        defmodule AggTest do
          import DataSchema, only: [data_schema: 1]
          data_schema(has_one: {:foo, "foo", "ahhh", optional?: true})
        end
      end)

      assert_raise(DataSchema.InvalidSchemaError, message, fn ->
        defmodule AggTest do
          import DataSchema, only: [data_schema: 1]
          data_schema(has_one: {:foo, "foo", "ahhh"})
        end
      end)
    end

    test "we allow mixing compile time and inline schemas" do
      defmodule BlogPostInline do
        import DataSchema, only: [data_schema: 1]

        data_schema(
          has_one: {:draft, "draft", {DraftPost, []}},
          has_many:
            {:commenta, "comments", {%{}, [field: {:text, "text", &DataSchemaTest.to_stringg/1}]}}
        )
      end

      assert BlogPostInline.__data_schema_fields() == [
               has_one: {:draft, "draft", {DataSchemaTest.DraftPost, []}},
               has_many:
                 {:commenta, "comments",
                  {%{}, [field: {:text, "text", &DataSchemaTest.to_stringg/1}]}}
             ]

      defmodule BlogPostInlineStruct do
        import DataSchema, only: [data_schema: 1]

        data_schema(
          has_one: {:draft, "draft", {%DraftPost{content: nil}, []}},
          has_many:
            {:commenta, "comments", {%{}, [field: {:text, "text", &DataSchemaTest.to_stringg/1}]}}
        )
      end

      assert BlogPostInlineStruct.__data_schema_fields() == [
               has_one: {:draft, "draft", {%DataSchemaTest.DraftPost{content: nil}, []}},
               has_many:
                 {:commenta, "comments",
                  {%{}, [field: {:text, "text", &DataSchemaTest.to_stringg/1}]}}
             ]
    end
  end

  # ============================== to_struct/2==============================================
  # no-options.
  defmodule DaftPost do
    import DataSchema, only: [data_schema: 1]
    data_schema(field: {:content, "content", &{:ok, to_string(&1)}})
  end

  defmodule BlagPost do
    import DataSchema, only: [data_schema: 1]

    @mapping [
      field: {:date, "date", &Date.from_iso8601/1},
      field: {:time, "time", &Time.from_iso8601/1}
    ]
    data_schema(
      field: {:content, "content", fn x -> {:ok, to_string(x)} end},
      has_many: {:comments, "comments", Comment},
      has_one: {:draft, "draft", DaftPost},
      aggregate: {:post_datetime, @mapping, &BlagPost.to_datetime/1}
    )

    def to_datetime(%{date: date, time: time}) do
      NaiveDateTime.new(date, time)
    end
  end

  describe "to_struct/2" do
    # We need to test every combo of field failing really. like has_one fails. etc nested shit.
    test "aggregate: if a casting function returns an error we stop creating the struct and return the error" do
      input = %{
        "content" => "This is a blog post",
        "comments" => [%{"text" => "This is a comment"}, %{"text" => "This is another comment"}],
        "draft" => %{"content" => "This is a draft blog post"},
        "date" => "not a date",
        "time" => "14:00:00",
        "metadata" => %{"rating" => 0}
      }

      blog = DataSchema.to_struct(input, BlagPost)

      assert blog ==
               {:error,
                %DataSchema.Errors{
                  errors: [post_datetime: %DataSchema.Errors{errors: [date: :invalid_format]}]
                }}
    end

    defmodule FieldError do
      import DataSchema, only: [data_schema: 1]
      data_schema(field: {:thing, "thing", fn _ -> :error end})
    end

    test "errors on :field field stop and return the error " do
      input = %{"thing" => "This is a blog post"}

      blog = DataSchema.to_struct(input, FieldError)

      assert blog == {:error, %DataSchema.Errors{errors: [thing: "There was an error!"]}}
    end

    defmodule Has do
      import DataSchema, only: [data_schema: 1]
      data_schema(field: {:integer, "int", fn x -> {:ok, x} end})

      def cast(nil), do: :error

      def cast(data) do
        {:ok, DataSchema.to_struct(data, __MODULE__)}
      end
    end

    defmodule HasOneError do
      import DataSchema, only: [data_schema: 1]
      data_schema(has_one: {:thing, "thing", Has})
    end

    test "errors on :has_one" do
      # nil is an error if the field is not optional which they aren't by default.
      # But if they _are_ optional then how do we make it not an error?
      input = %{"thing" => %{}}
      blog = DataSchema.to_struct(input, HasOneError)

      assert blog ==
               {
                 :error,
                 %DataSchema.Errors{
                   errors: [
                     thing: %DataSchema.Errors{
                       errors: [
                         integer: "Field was required but value supplied is considered empty"
                       ]
                     }
                   ]
                 }
               }

      input = %{"thing" => nil}
      blog = DataSchema.to_struct(input, HasOneError)

      assert blog ==
               {
                 :error,
                 %DataSchema.Errors{
                   errors: [
                     thing: "Field was required but value supplied is considered empty"
                   ]
                 }
               }
    end

    defmodule ListOfError do
      import DataSchema, only: [data_schema: 1]
      data_schema(list_of: {:thing, "thing", fn _ -> :error end})
    end

    test "errors on :list_of" do
      input = %{"thing" => [%{}]}
      blog = DataSchema.to_struct(input, ListOfError)
      assert blog == {:error, %DataSchema.Errors{errors: [thing: "There was an error!"]}}
    end

    defmodule Many do
      import DataSchema, only: [data_schema: 1]
      data_schema(field: {:thing, "thing", fn x -> {:ok, x} end})
    end

    defmodule HasManyError do
      import DataSchema, only: [data_schema: 1]
      data_schema(has_many: {:things, "things", Many})
    end

    test "errors on has_many" do
      input = %{"things" => [%{}]}
      blog = DataSchema.to_struct(input, HasManyError)

      assert blog ==
               {:error,
                %DataSchema.Errors{
                  errors: [
                    things: %DataSchema.Errors{
                      errors: [
                        thing: "Field was required but value supplied is considered empty"
                      ]
                    }
                  ]
                }}
    end
  end

  test "list of field that returns an empty value from the cast fn errors" do
    schema = [
      list_of: {:things, "a", fn x -> {:ok, x} end, empty_values: [[]]}
    ]

    input = %{"a" => []}
    result = DataSchema.to_struct(input, %{}, schema, DataSchema.MapAccessor)

    assert result ==
             {:error,
              %DataSchema.Errors{
                errors: [things: "Field was required but value supplied is considered empty"]
              }}
  end

  describe "empty aggregate tests" do
    test "if casting an aggregate returns an empty value we error" do
      schema = [
        aggregate:
          {:agg,
           [
             field: {:a, "a", &to_stringg/1},
             field: {:b, "b", &to_stringg/1}
           ], fn _ -> {:ok, %{}} end, empty_values: [%{}]}
      ]

      input = %{"a" => 1, "b" => 2}
      result = DataSchema.to_struct(input, %{}, schema, DataSchema.MapAccessor)

      assert result ==
               {:error,
                %DataSchema.Errors{
                  errors: [agg: "Field was required but value supplied is considered empty"]
                }}
    end

    test "if the resolution of aggregate is empty we error" do
      schema = [
        aggregate:
          {:agg,
           [
             field: {:a, "a", &{:ok, &1}, optional?: true},
             field: {:b, "b", &{:ok, &1}, optional?: true}
             # This makes me realise that a function might be better. Though with aggregate
             # your cast fn could implement the empty checks...
           ], fn x -> {:ok, x} end, empty_values: [%{a: nil, b: nil}]}
      ]

      input = %{}
      result = DataSchema.to_struct(input, %{}, schema, DataSchema.MapAccessor)

      assert result ==
               {:error,
                %DataSchema.Errors{
                  errors: [agg: "Field was required but value supplied is considered empty"]
                }}
    end
  end

  # with options...
end
