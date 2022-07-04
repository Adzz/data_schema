defmodule Duffel.Link.DataSchema.Boolean do
  @moduledoc """
  A data schema cast function that casts to a boolean.
  """
  @behaviour DataSchema.CastBehaviour
  @impl true
  def cast("true"), do: {:ok, true}
  def cast("false"), do: {:ok, false}
  def cast(nil), do: {:ok, nil}
end
