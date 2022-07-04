defmodule Duffel.Link.DataSchema.JoinWithSpaces do
  @moduledoc """
  A data schema cast function that takes a list of strings and joins them into one string
  with a space between elements.
  """
  @behaviour DataSchema.CastBehaviour
  @impl true
  def cast(%{value: value}), do: cast(value)
  def cast(nil), do: {:ok, nil}
  def cast([]), do: {:ok, nil}
  def cast([_ | _] = strings), do: {:ok, Enum.join(strings, " ")}
end
