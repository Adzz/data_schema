defmodule DataSchema.String do
  @moduledoc """
  A simple type for your data schemas that will cast incoming data to a string.
  """

  # Nil is a sticking point..... Do we guard against it? Allow it? HAve another
  # &Non.null(String, &1) ?
  def cast(string) when is_binary(string), do: string
  def cast(string), do: to_string(string)
end
