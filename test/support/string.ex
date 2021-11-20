defmodule DataSchema.String do
  @moduledoc """
  just used for testing.
  """

  def cast(string) when is_binary(string), do: {:ok, string}
  def cast(string), do: {:ok, to_string(string)}
end
