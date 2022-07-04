defmodule Duffel.Link.DataSchema.IntegerType do
  @moduledoc """
  Provides a casting function that can be used in DataSchemas which turns a value into an
  integer.
  """
  @behaviour DataSchema.CastBehaviour

  def cast(nil), do: {:ok, nil}
  def cast(value) when is_binary(value), do: {:ok, String.to_integer(value)}
  def cast(value) when is_integer(value), do: {:ok, value}
  def cast(value), do: {:error, "Can't be cast to integer: #{inspect(value)}"}
end
