# Stopping to_struct when there is an error

When we create a struct from a schema `DataSchema.to_struct/2` a casting function can return an error, optionally with a message, but there are two ways we could handle this error. The first is to stop immediately and return that error. The other is to collect all of the errors from all cast functions and return all of them to the user.

Each has its place and both are possible in DataSchema. Contrast the following approaches:

### `DataSchema.to_struct/2`

```elixir
defmodule BlagPost do
  import DataSchema, only: [data_schema: 1]

  data_schema(
    aggregate: {:post_datetime, %{date: "date", time: "time"}, &BlagPost.to_datetime/1}
  )

  def to_datetime(%{date: date_string, time: time_string}) do
    with {:date, {:ok, date}} <- {:date, Date.from_iso8601(date_string)},
         {:time, {:ok, time}} <- {:time, Time.from_iso8601(time_string)} do
      NaiveDateTime.new(date, time)
    else
      {:date, {:error, _}} -> {:error, "Date is invalid: #{inspect(date_string)}"}
      {:time, {:error, _}} -> {:error, "Time is invalid: #{inspect(time_string)}"}
    end
  end
end

input = %{
  "date" => "not a date",
  "time" => "14:00:00",
}

DataSchema.to_struct(input, BlagPost)

DataSchema.to_struct(input, BlagPost, collect_errors: true)


# => {:error, "Date is invalid: \"not a date\""}
```

### `DataSchema.to_struct/2`

```elixir
defmodule BlogPost do
  import DataSchema, only: [data_schema: 1]

  data_schema(
    aggregate: {:post_datetime, %{date: "date", time: "time"}, &BlogPost.to_datetime/1}
  )

  def to_datetime(%{date: date_string, time: time_string}) do
    date = Date.from_iso8601!(date_string)
    time = Time.from_iso8601!(time_string)
    NaiveDateTime.new(date, time)
  end
end

input = %{
  "date" => "not a date",
  "time" => "14:00:00",
}

DataSchema.to_struct(input, BlogPost)
# => ** (ArgumentError) cannot parse "not a date" as date, reason: :invalid_format
```
