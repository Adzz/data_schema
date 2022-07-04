defmodule Duffel.Link.DataSchema.DateType do
  @moduledoc """
  Provides a casting function that can be used in DataSchemas which turns a value into a
  Date.
  """
  @behaviour DataSchema.CastBehaviour

  def cast(nil), do: {:ok, nil}
  def cast(value) when is_binary(value), do: {:ok, Date.from_iso8601!(value)}
  def cast(value), do: {:error, "Can't be cast to Date: #{inspect(value)}"}
end
