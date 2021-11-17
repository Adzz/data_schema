# Stopping to_struct when there is an error

There are two ways to create a struct from a schema `DataSchema.to_struct!/2` and `DataSchema.to_struct/2`. The crucial difference is that with the latter you can have your casting functions return an `:error` or an error tuple and the creation of the struct will halt and the error will be returned.

In contrast `DataSchema.to_struct!` will always put whatever is returned from the casting functions into the struct so the only way to fail is to raise an error in the casting function.

Contrast the following approaches:

### `DataSchema.to_struct/2`

```elixir
defmodule BlagPost do
  import DataSchema, only: [data_schema: 1]

  data_schema(
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

input = %{
  "date" => "not a date",
  "time" => "14:00:00",
}

DataSchema.to_struct(input, BlagPost)
# => {:error, "Date is invalid: \"not a date\""}
```

### `DataSchema.to_struct!/2`

```elixir
defmodule BlogPost do
  import DataSchema, only: [data_schema: 1]

  data_schema(
    aggregate: {:post_datetime, %{date: "date", time: "time"}, &BlogPost.to_datetime/1}
  )

  def to_datetime(%{date: date_string, time: time_string}) do
    date = Date.from_iso8601!(date_string)
    time = Time.from_iso8601!(time_string)
    {:ok, datetime} = NaiveDateTime.new(date, time)
    datetime
  end
end

input = %{
  "date" => "not a date",
  "time" => "14:00:00",
}

DataSchema.to_struct(input, BlogPost)
# => ** (ArgumentError) cannot parse "not a date" as date, reason: :invalid_format
```
