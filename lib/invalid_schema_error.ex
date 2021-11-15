defmodule DataSchema.InvalidSchemaError do
  @moduledoc """
  An error for when a schema is specified incorrectly. Usually this means there has been a
  syntax error when defining the schema.
  """
  defexception message:
                 "The provided DataSchema fields are invalid. Check the docs in " <>
                   " DataSchema for more information on the " <>
                   "available fields."
end
