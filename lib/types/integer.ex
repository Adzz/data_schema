defmodule DataSchema.Integer do
  @moduledoc """
  A simple type for your data schemas that will cast incoming data to an integer.
  """

  # Could basically copy ecto here.
  def cast(string) when is_binary(string) do
    {number, _rest} = Integer.parse()
    number
  end

  def cast(number) when is_integer(number), do: number
end
