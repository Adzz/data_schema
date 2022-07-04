defmodule Duffel.Link.DataSchema.TimeType do
  @moduledoc """
  Provides a casting function that can be used in DataSchemas which turns a value into a Time.
  Supported strings formats: HH:MM and HH:MM:SS.
  """
  @behaviour DataSchema.CastBehaviour

  def cast(nil), do: {:ok, nil}

  def cast(value) when is_binary(value) do
    case value do
      <<hours::2-bytes, ":", minutes::2-bytes>> ->
        hours = String.to_integer(hours)
        minutes = String.to_integer(minutes)
        Time.new(hours, minutes, 0)

      string ->
        Time.from_iso8601(string)
    end
  end

  def cast(value), do: {:error, "Can't be cast to Time: #{inspect(value)}"}
end
