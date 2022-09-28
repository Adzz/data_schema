defmodule DataSchema.DateCast do
  @moduledoc """
  Used for testing only
  """
  def cast("raise agg"), do: {:ok, "raise agg"}
  def cast("raise"), do: raise("no m8")
  def cast(x), do: Date.from_iso8601(x)
end

defmodule DataSchema.RaiseString do
  @moduledoc """
  Used for testing only
  """
  def cast("raise"), do: raise("no m8")
  def cast(x), do: {:ok, x}
end
