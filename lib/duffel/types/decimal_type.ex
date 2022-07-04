defmodule Duffel.Link.DataSchema.DecimalType do
  @moduledoc """
  Provides a casting function that can be used in DataSchemas which turns a value into a
  Decimal.
  """
  @behaviour DataSchema.CastBehaviour

  def cast(value) when is_binary(value), do: {:ok, Decimal.new(value)}
  def cast(value) when is_integer(value), do: {:ok, Decimal.new(value)}
  def cast(value) when is_float(value), do: {:ok, Decimal.from_float(value)}
  def cast(nil), do: {:ok, nil}
  def cast(value), do: {:error, "Value can't be cast to Decimal: #{inspect(value)}"}
end
