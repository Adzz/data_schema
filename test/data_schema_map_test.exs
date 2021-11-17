defmodule DataSchemaMapTest do
  use ExUnit.Case, async: true

  defmodule DraftPost do
    import DataSchema, only: [data_schema: 2]

    data_schema([field: {:content, "content", DataSchema.String}], DataSchema.MapAccessor)
  end

  defmodule Comment do
    import DataSchema, only: [data_schema: 2]

    data_schema([field: {:text, "text", DataSchema.String}], DataSchema.MapAccessor)

    def cast(data) do
      DataSchema.to_struct(data, __MODULE__)
    end
  end

  defmodule BlogPost do
    import DataSchema, only: [data_schema: 2]

    data_schema(
      [
        field: {:content, "content", DataSchema.String},
        list_of: {:comments, "comments", Comment},
        has_one: {:draft, "draft", DraftPost},
        aggregate: {:post_datetime, %{date: "date", time: "time"}, &BlogPost.to_datetime/1}
      ],
      DataSchema.MapAccessor
    )

    def to_datetime(%{date: date_string, time: time_string}) do
      date = Date.from_iso8601!(date_string)
      time = Time.from_iso8601!(time_string)
      {:ok, datetime} = NaiveDateTime.new(date, time)
      datetime
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

  describe "to_struct/2" do
    test "casts a :field" do
      blog = DataSchema.to_struct(source_data(), BlogPost)

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
      blog = DataSchema.to_struct(source_data(), BlogPost)

      assert blog.__struct__ == DataSchemaMapTest.BlogPost
      assert blog.post_datetime == ~N[2021-11-11 14:00:00]
    end

    test "casts all list_of fields" do
      blog = DataSchema.to_struct(source_data(), BlogPost)

      assert blog.__struct__ == DataSchemaMapTest.BlogPost

      assert blog.comments == [
               %DataSchemaMapTest.Comment{text: "This is a comment"},
               %DataSchemaMapTest.Comment{text: "This is another comment"}
             ]
    end

    test "casts an embed_one field" do
      blog = DataSchema.to_struct(source_data(), BlogPost)

      assert blog.__struct__ == DataSchemaMapTest.BlogPost

      assert blog.draft == %DataSchemaMapTest.DraftPost{content: "This is a draft blog post"}
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
