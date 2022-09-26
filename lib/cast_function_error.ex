defmodule DataSchema.CastFunctionError do
  @moduledoc """
  An error for when a casting function does not return the correct data.
  """
  defexception [:message]
end
