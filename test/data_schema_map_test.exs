defmodule DataSchemaMapTest do
  use ExUnit.Case, async: true

  defmodule DraftPost do
    import DataSchema, only: [data_schema: 1]
    data_schema(field: {:content, "content", DataSchema.String})
  end

  defmodule Comment do
    import DataSchema, only: [data_schema: 1]
    data_schema(field: {:text, "text", DataSchema.String})
  end

  defmodule BlogPost do
    import DataSchema, only: [data_schema: 1]

    # Test this code path.
    defmodule DateTime do
      import DataSchema, only: [data_schema: 1]

      data_schema(
        field:
          {:date, "date",
           fn
             "raise agg" -> {:ok, "raise agg"}
             "raise" -> raise "no m8"
             x -> Date.from_iso8601(x)
           end},
        field: {:time, "time", &Time.from_iso8601/1}
      )
    end

    data_schema(
      field:
        {:content, "content",
         fn
           "raise" -> raise "nope"
           x -> DataSchema.String.cast(x)
         end},
      has_many: {:comments, "comments", Comment},
      has_one: {:draft, "draft", DraftPost},
      aggregate: {:post_datetime, DateTime, &BlogPost.to_datetime/1}
    )

    def to_datetime(%{date: "raise agg"}) do
      raise "NoOPE"
    end

    def to_datetime(%{date: date, time: time}) do
      NaiveDateTime.new(date, time)
    end
  end

  test "Fields are required by default" do
    error_message =
      "the following keys must also be given when building struct DataSchemaMapTest.BlogPost: [:post_datetime, :draft, :comments, :content]"

    assert_raise(ArgumentError, error_message, fn ->
      # Not providing all required keys is a compiler error so we quote it otherwise we'll
      # get a compiler error before the test runs. But strangely when we compile the
      # quoted code we end up with an ArgumentError. But we test the same thing essentially.
      ast =
        quote do
          %BlogPost{}
        end

      Code.compile_quoted(ast)
    end)
  end

  test "a private function is added which returns the map accessor" do
    assert BlogPost.__data_accessor() == DataSchema.MapAccessor
  end

  describe "to_struct!/2" do
    test "casts a :field" do
      {:ok, blog} = DataSchema.to_struct(source_data(), BlogPost)

      assert blog.__struct__ == DataSchemaMapTest.BlogPost
      assert blog.content == "This is a blog post"

      assert blog == %DataSchemaMapTest.BlogPost{
               comments: [
                 %DataSchemaMapTest.Comment{text: "This is a comment"},
                 %DataSchemaMapTest.Comment{text: "This is another comment"}
               ],
               content: "This is a blog post",
               draft: %DataSchemaMapTest.DraftPost{content: "This is a draft blog post"},
               post_datetime: ~N[2021-11-11 14:00:00]
             }
    end

    test "aggregate field works too" do
      {:ok, blog} = DataSchema.to_struct(source_data(), BlogPost)

      assert blog.__struct__ == DataSchemaMapTest.BlogPost
      assert blog.post_datetime == ~N[2021-11-11 14:00:00]
    end

    test "casts all has_many fields" do
      {:ok, blog} = DataSchema.to_struct(source_data(), BlogPost)

      assert blog.__struct__ == DataSchemaMapTest.BlogPost

      assert blog.comments == [
               %DataSchemaMapTest.Comment{text: "This is a comment"},
               %DataSchemaMapTest.Comment{text: "This is another comment"}
             ]
    end

    test "casts an embed_one field" do
      {:ok, blog} = DataSchema.to_struct(source_data(), BlogPost)

      assert blog.__struct__ == DataSchemaMapTest.BlogPost
      assert blog.draft == %DataSchemaMapTest.DraftPost{content: "This is a draft blog post"}
    end

    test "when a field cast fn raises we capture that and re-raise" do
      source_data = %{
        "content" => "raise",
        "comments" => [%{"text" => "This is a comment"}, %{"text" => "This is another comment"}],
        "draft" => %{"content" => "This is a draft blog post"},
        "date" => "2021-11-11",
        "time" => "14:00:00",
        "metadata" => %{"rating" => 0}
      }

      message = """


      Unexpected error when casting value "raise"
      for field :content in schema DataSchemaMapTest.BlogPost

      Full path to field was:

            Field  :content in DataSchemaMapTest.BlogPost

      The casting function raised the following error:

      ** (RuntimeError) nope
      """

      assert_raise(DataSchema.CastFunctionError, message, fn ->
        DataSchema.to_struct(source_data, BlogPost)
      end)
    end

    test "when a field on a has_one cast fn raises we capture that and re-raise" do
      source_data = %{
        "content" => "one upon a time",
        "comments" => [%{"text" => "This is a comment"}, %{"text" => "This is another comment"}],
        "draft" => %{"content" => "raise"},
        "date" => "2021-11-11",
        "time" => "14:00:00",
        "metadata" => %{"rating" => 0}
      }

      message = """


      Unexpected error when casting value "raise"
      for field :content in schema DataSchemaMapTest.DraftPost

      Full path to field was:

            Field  :content in DataSchemaMapTest.DraftPost
      Under Field  :draft in DataSchemaMapTest.BlogPost

      The casting function raised the following error:

      ** (RuntimeError) Nope!
      """

      assert_raise(DataSchema.CastFunctionError, message, fn ->
        DataSchema.to_struct(source_data, BlogPost)
      end)
    end

    test "when a field on a has_many cast fn raises we capture that and re-raise" do
      source_data = %{
        "content" => "one upon a time",
        "comments" => [%{"text" => "raise"}, %{"text" => "This is another comment"}],
        "draft" => %{"content" => "ssssssssss"},
        "date" => "2022-01-01",
        "time" => "14:00:00",
        "metadata" => %{"rating" => 0}
      }

      message = """


      Unexpected error when casting value "raise"
      for field :text in schema DataSchemaMapTest.Comment

      Full path to field was:

            Field  :text in DataSchemaMapTest.Comment
      Under Field  :comments in DataSchemaMapTest.BlogPost

      The casting function raised the following error:

      ** (RuntimeError) Nope!
      """

      assert_raise(DataSchema.CastFunctionError, message, fn ->
        DataSchema.to_struct(source_data, BlogPost)
      end)
    end

    test "when the aggregate cast fn raises in a runtime schema" do
      source_data = %{
        "content" => "one upon a time",
        "comments" => [%{"text" => "raised right"}, %{"text" => "This is another comment"}],
        "draft" => %{"content" => "ssssssssss"},
        "date" => "raise agg",
        "time" => "14:00:00",
        "metadata" => %{"rating" => 0}
      }

      schema = [
        aggregate:
          {:post_datetime,
           [
             field: {:date, "date", DataSchema.DateCast},
             field: {:time, "time", DataSchema.TimeCast}
           ], &DataSchemaMapTest.BlogPost.to_datetime/1}
      ]

      message = """


      Unexpected error when casting value %{date: "raise agg", time: ~T[14:00:00]}
      for field :post_datetime in this part of the schema:

      @aggregate_fields [
        field: {:date, "date", DataSchema.DateCast},
        field: {:time, "time", DataSchema.TimeCast},
      ]
      aggregate: {:post_datetime, @aggregate_fields, &DataSchemaMapTest.BlogPost.to_datetime/1},


      Full path to field was:

            Field  :post_datetime

      The casting function raised the following error:

      ** (RuntimeError) NoOPE
      """

      assert_raise(DataSchema.CastFunctionError, message, fn ->
        DataSchema.to_struct(source_data, %{}, schema, DataSchema.MapAccessor)
      end)
    end

    test "when the aggregate has an aggregate and cast fn raises in a runtime schema" do
      source_data = %{
        "content" => "one upon a time",
        "comments" => [%{"text" => "raised right"}, %{"text" => "This is another comment"}],
        "draft" => %{"content" => "ssssssssss"},
        "date" => "2022-01-01",
        "time" => "14:00:00",
        "metadata" => %{"rating" => 0}
      }

      agg_fields = [
        aggregate: {:test, [field: {:date, "date", DataSchema.DateCast}], AggType},
        field: {:time, "time", DataSchema.TimeCast}
      ]

      schema = [
        aggregate: {:post_datetime, agg_fields, &DataSchemaMapTest.BlogPost.to_datetime/1}
      ]

      message = """


      Unexpected error when casting value %{date: ~D[2022-01-01]}
      for field :test in this part of the schema:

      @aggregate_fields [
        field: {:date, "date", DataSchema.DateCast},
      ]
      aggregate: {:test, @aggregate_fields, AggType},


      Full path to field was:

            Field  :test
      Under Field  :post_datetime

      The casting function raised the following error:

      ** (UndefinedFunctionError) function AggType.cast/1 is undefined (module AggType is not available)
      """

      assert_raise(DataSchema.CastFunctionError, message, fn ->
        DataSchema.to_struct(source_data, %{}, schema, DataSchema.MapAccessor)
      end)
    end

    test "when the aggregate cast fn raises" do
      source_data = %{
        "content" => "one upon a time",
        "comments" => [%{"text" => "raised right"}, %{"text" => "This is another comment"}],
        "draft" => %{"content" => "ssssssssss"},
        "date" => "raise agg",
        "time" => "14:00:00",
        "metadata" => %{"rating" => 0}
      }

      message = """


      Unexpected error when casting value %DataSchemaMapTest.BlogPost.DateTime{date: "raise agg", time: ~T[14:00:00]}
      for field :post_datetime in schema DataSchemaMapTest.BlogPost

      Full path to field was:

            Field  :post_datetime in DataSchemaMapTest.BlogPost

      The casting function raised the following error:

      ** (RuntimeError) NoOPE
      """

      assert_raise(DataSchema.CastFunctionError, message, fn ->
        DataSchema.to_struct(source_data, BlogPost)
      end)
    end

    test "when an aggregate field raises" do
      source_data = %{
        "content" => "one upon a time",
        "comments" => [%{"text" => "raised right"}, %{"text" => "This is another comment"}],
        "draft" => %{"content" => "ssssssssss"},
        "date" => "raise",
        "time" => "14:00:00",
        "metadata" => %{"rating" => 0}
      }

      message = """


      Unexpected error when casting value "raise"
      for field :date in schema DataSchemaMapTest.BlogPost.DateTime

      Full path to field was:

            Field  :date in DataSchemaMapTest.BlogPost.DateTime
      Under Field  :post_datetime in DataSchemaMapTest.BlogPost

      The casting function raised the following error:

      ** (RuntimeError) no m8
      """

      assert_raise(DataSchema.CastFunctionError, message, fn ->
        DataSchema.to_struct(source_data, BlogPost)
      end)
    end

    test "when a field on a list_of cast fn raises we capture that and re-raise" do
      source_data = %{
        "content" => "one upon a time",
        "comments" => ["raise", %{"text" => "This is another comment"}],
        "draft" => %{"content" => "ssssssssss"},
        "date" => "2022-01-01",
        "time" => "14:00:00",
        "metadata" => %{"rating" => 0}
      }

      schema = [
        list_of: {:comments, "comments", DataSchema.RaiseString}
      ]

      message = """


      Unexpected error when casting value "raise"
      for field :comments in this part of the schema:

      list_of: {:comments, "comments", DataSchema.RaiseString},

      Full path to field was:

            Field  :comments

      The casting function raised the following error:

      ** (RuntimeError) no m8
      """

      assert_raise(DataSchema.CastFunctionError, message, fn ->
        DataSchema.to_struct(source_data, %{}, schema, DataSchema.MapAccessor)
      end)
    end
  end

  defp source_data do
    %{
      "content" => "This is a blog post",
      "comments" => [%{"text" => "This is a comment"}, %{"text" => "This is another comment"}],
      "draft" => %{"content" => "This is a draft blog post"},
      "date" => "2021-11-11",
      "time" => "14:00:00",
      "metadata" => %{"rating" => 0}
    }
  end
end
