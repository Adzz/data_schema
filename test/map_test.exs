defmodule DataSchema.MapTest do
  use ExUnit.Case, async: true

  defmodule DraftPost do
    import DataSchema.Map, only: [map_schema: 1]

    map_schema(field: {:content, "content", DataSchema.String})
  end

  defmodule Comment do
    import DataSchema.Map, only: [map_schema: 1]

    map_schema(field: {:text, "text", DataSchema.String})

    def cast(data) do
      DataSchema.to_struct(data, __MODULE__)
    end
  end

  defmodule BlogPost do
    import DataSchema.Map, only: [map_schema: 1]

    map_schema(
      field: {:content, "content", DataSchema.String},
      list_of: {:comments, "comments", Comment},
      has_one: {:draft, "draft", DraftPost},
      aggregate: {:post_datetime, %{date: "date", time: "time"}, &BlogPost.to_datetime/1}
    )

    def to_datetime(%{date: date_string, time: time_string}) do
      date = Date.from_iso8601!(date_string)
      time = Time.from_iso8601!(time_string)
      {:ok, datetime} = NaiveDateTime.new(date, time)
      datetime
    end
  end

  describe "map_schema/1" do
    test "a private function is added which returns the map accessor" do
      assert BlogPost.__data_accessor() == DataSchema.MapAccessor
    end

    test "fields are added as a secret fn" do
      assert BlogPost.__data_schema_fields() == [
               field: {:content, "content", DataSchema.String},
               list_of: {:comments, "comments", DataSchema.MapTest.Comment},
               has_one: {:draft, "draft", DataSchema.MapTest.DraftPost},
               aggregate:
                 {:post_datetime, %{date: "date", time: "time"},
                  &DataSchema.MapTest.BlogPost.to_datetime/1}
             ]
    end

    test "creates a map schema with the default MapAccessor as the accessor" do
      input = %{
        "content" => "This is a blog post",
        "comments" => [%{"text" => "This is a comment"}, %{"text" => "This is another comment"}],
        "draft" => %{"content" => "This is a draft blog post"},
        "date" => "2021-11-11",
        "time" => "14:00:00",
        "metadata" => %{"rating" => 0}
      }

      blog = DataSchema.to_struct(input, BlogPost)

      assert blog == %DataSchema.MapTest.BlogPost{
               comments: [
                 %DataSchema.MapTest.Comment{text: "This is a comment"},
                 %DataSchema.MapTest.Comment{text: "This is another comment"}
               ],
               content: "This is a blog post",
               draft: %DataSchema.MapTest.DraftPost{content: "This is a draft blog post"},
               post_datetime: ~N[2021-11-11 14:00:00]
             }
    end
  end
end
