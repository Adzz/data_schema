defmodule DataSchema.DataAccessBehaviour do
  @moduledoc """
  Defines how DataSchema should access data for each given field type.
  """

  @callback field(any(), any()) :: any()
  @callback list_of(any(), any()) :: any()
  @callback has_one(any(), any()) :: any()
  @callback aggregate(any(), any()) :: any()
end
