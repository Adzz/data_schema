defmodule Duffel.Link.DataSchema.NaiveDateTimeType do
  @moduledoc """
  Provides a casting function that can be used in DataSchemas which turns a value into a
  naive datetime
  """
  @behaviour DataSchema.CastBehaviour

  def cast(nil), do: {:ok, nil}

  def cast(%{date: %Date{} = date, time: %Time{} = time}) do
    NaiveDateTime.new(date, time)
  end

  def cast(value) when is_binary(value), do: {:ok, NaiveDateTime.from_iso8601!(value)}
  def cast(value), do: {:error, "Can't be cast to NaiveDateTime: #{inspect(value)}"}
end
