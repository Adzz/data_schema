defmodule DataSchema.DataAccessBehaviour do
  @moduledoc """
  Defines how DataSchema should access data for each given field type. When we create a
  struct defined by the schema we will visit each struct field in turn and attempt to
  extract values from the source data to pass to the casting function. Modules that
  implement this behaviour are implementing how to access data in the source for each
  kind of field.
  """

  # So A Thing :tm about this is what happens if a new type of field comes along..... Yes
  # that'd be a breaking change.
  @callback field(any(), any()) :: any()
  @callback list_of(any(), any()) :: any()
  @callback has_one(any(), any()) :: any()
  @callback aggregate(any(), any()) :: any()
end
