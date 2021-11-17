defmodule DataSchemaTest do
  use ExUnit.Case, async: true

  defmodule DraftPost do
    import DataSchema, only: [data_schema: 1]
    data_schema(field: {:content, "content", DataSchema.String})
  end

  defmodule Comment do
    import DataSchema, only: [data_schema: 1]
    data_schema(field: {:text, "text", DataSchema.String})
    def cast(data), do: DataSchema.to_struct!(data, __MODULE__)
  end

  defmodule BlogPost do
    import DataSchema, only: [data_schema: 1]

    data_schema(
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

      blog = DataSchema.to_struct!(input, BlogPost)

      assert blog == %DataSchemaTest.BlogPost{
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

    test "fields are added as a secret fn" do
      assert BlogPost.__data_schema_fields() == [
               field: {:content, "content", DataSchema.String},
               list_of: {:comments, "comments", DataSchemaTest.Comment},
               has_one: {:draft, "draft", DataSchemaTest.DraftPost},
               aggregate:
                 {:post_datetime, %{date: "date", time: "time"},
                  &DataSchemaTest.BlogPost.to_datetime/1}
             ]
    end
  end

  # ============================== to_struct/2==============================================

  defmodule DaftPost do
    import DataSchema, only: [data_schema: 1]
    data_schema(field: {:content, "content", &{:ok, DataSchema.String.cast(&1)}})
  end

  defmodule BlagPost do
    import DataSchema, only: [data_schema: 1]

    data_schema(
      field: {:content, "content", fn x -> {:ok, DataSchema.String.cast(x)} end},
      list_of: {:comments, "comments", fn x -> {:ok, Comment.cast(x)} end},
      has_one: {:draft, "draft", DaftPost},
      aggregate: {:post_datetime, %{date: "date", time: "time"}, &BlagPost.to_datetime/1}
    )

    def to_datetime(%{date: date_string, time: time_string}) do
      with {:date, {:ok, date}} <- {:date, Date.from_iso8601(date_string)},
           {:time, {:ok, time}} <- {:time, Time.from_iso8601(time_string)},
           {:ok, datetime} <- NaiveDateTime.new(date, time) do
        datetime
      else
        {:date, {:error, _}} -> {:error, "Date is invalid: #{inspect(date_string)}"}
        {:time, {:error, _}} -> {:error, "Time is invalid: #{inspect(time_string)}"}
      end
    end
  end

  describe "to_struct/2" do
    # We need to test every combo of field failing really. like has_one fails. etc nested shit.
    test "if a casting function returns an error we stop creating the struct and return the error" do
      input = %{
        "content" => "This is a blog post",
        "comments" => [%{"text" => "This is a comment"}, %{"text" => "This is another comment"}],
        "draft" => %{"content" => "This is a draft blog post"},
        "date" => "not a date",
        "time" => "14:00:00",
        "metadata" => %{"rating" => 0}
      }

      blog = DataSchema.to_struct(input, BlagPost)

      assert blog == {:error, "Date is invalid: \"not a date\""}
    end
  end
end
