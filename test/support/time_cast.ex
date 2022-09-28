defmodule DataSchema.TimeCast do
  @moduledoc """
  Used for testing only
  """
  def cast(x), do: Time.from_iso8601(x)
end
