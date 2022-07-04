defmodule Duffel.Link.DataSchema.MoneyType do
  @moduledoc """
  Provides a casting function that can be used in DataSchemas which turns a value into an
  ex_money Money type
   
  """
  @behaviour DataSchema.CastBehaviour

  def cast(nil), do: {:ok, nil}

  def cast(%{amount: amount, currency: currency} = _value),
    do: {:ok, %{currency: currency, amount: amount}}
end
