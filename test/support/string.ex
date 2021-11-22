defmodule DataSchema.String do
  @moduledoc """
  just used for testing.
  """
  @behaviour DataSchema.CastBehaviour

  @impl true
  def cast(string) when is_binary(string), do: {:ok, string}
  @impl true
  def cast(string), do: {:ok, to_string(string)}
end
