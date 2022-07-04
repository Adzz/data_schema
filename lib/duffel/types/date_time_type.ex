defmodule Duffel.Link.DataSchema.DateTimeType do
  @moduledoc """
  Provides a casting function that can be used in DataSchemas which turns a value into a
   datetime
  """
  @behaviour DataSchema.CastBehaviour

  def cast(nil), do: {:ok, nil}

  def cast(value) when is_binary(value) do
    {:ok, datetime, _} = DateTime.from_iso8601(value)
    {:ok, datetime}
  end

  def cast(value), do: {:error, "Can't be cast to DateTime: #{inspect(value)}"}
end
