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
        field: {:date, "date", &Date.from_iso8601/1},
        field: {:time, "time", &Time.from_iso8601/1}
      )
    end

    data_schema(
      field: {:content, "content", DataSchema.String},
      has_many: {:comments, "comments", Comment},
      has_one: {:draft, "draft", DraftPost},
      aggregate: {:post_datetime, DateTime, &BlogPost.to_datetime/1}
    )

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
