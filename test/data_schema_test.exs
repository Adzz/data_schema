defmodule DataSchemaTest do
  use ExUnit.Case, async: true

  def to_stringg(x), do: {:ok, to_string(x)}

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

    data_schema(
      field: {:content, "content", &DataSchemaTest.to_stringg/1},
      has_many: {:comments, "comments", Comment},
      has_one: {:draft, "draft", DraftPost},
      aggregate: {:post_datetime, %{date: "date", time: "time"}, &BlogPost.to_datetime/1}
    )

    def to_datetime(%{date: date_string, time: time_string}) do
      date = Date.from_iso8601!(date_string)
      time = Time.from_iso8601!(time_string)
      NaiveDateTime.new(date, time)
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
               field: {:content, "content", &DataSchemaTest.to_stringg/1},
               has_many: {:comments, "comments", DataSchemaTest.Comment},
               has_one: {:draft, "draft", DataSchemaTest.DraftPost},
               aggregate:
                 {:post_datetime, %{date: "date", time: "time"},
                  &DataSchemaTest.BlogPost.to_datetime/1}
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

    data_schema(
      field: {:content, "content", fn x -> {:ok, to_string(x)} end},
      has_many: {:comments, "comments", Comment},
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

      assert blog == {:error, "Date is invalid: \"not a date\""}
    end

    defmodule FieldError do
      import DataSchema, only: [data_schema: 1]
      data_schema(field: {:thing, "thing", fn _ -> :error end})
    end

    test "errors on :field field stop and return the error " do
      input = %{"thing" => "This is a blog post"}

      blog = DataSchema.to_struct(input, FieldError)

      assert blog == :error
    end

    defmodule Has do
      import DataSchema, only: [data_schema: 1]
      data_schema(field: {:integer, "int", fn x -> {:error, x} end})

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
      # input = %{"thing" => nil} needs to work for both cases.
      input = %{"thing" => %{}}
      blog = DataSchema.to_struct(input, HasOneError)
      assert blog == {:error, "non null field was found to be null!"}
    end

    defmodule ListOfError do
      import DataSchema, only: [data_schema: 1]
      data_schema(list_of: {:thing, "thing", fn _ -> :error end})
    end

    test "errors on :list_of" do
      input = %{"thing" => [%{}]}
      blog = DataSchema.to_struct(input, ListOfError)
      assert blog == :error
    end

    defmodule Many do
      import DataSchema, only: [data_schema: 1]
      data_schema(field: {:thing, "thing", fn _ -> :error end})
    end

    defmodule HasManyError do
      import DataSchema, only: [data_schema: 1]
      data_schema(has_many: {:things, "things", Many})
    end

    test "errors on has_many" do
      input = %{"things" => [%{}]}
      blog = DataSchema.to_struct(input, HasManyError)
      assert blog == {:error, "non null field was found to be null!"}
    end
  end

  # with options...
end
