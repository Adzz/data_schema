defmodule DataSchema.CastBehaviour do
  @moduledoc """
  The casting function can either be a 1 arity function or a module that has a cast/1
  function implemented. This behaviour is to help ensure that cast/1 function looks the
  way DataSchema expects.
  """
  @doc """
  A doc should return an okay tuple with the casted value or an error tuple. For errors
  you can optionally provide a message that will be returned if `DataSchema.to_struct/2`
  fails.
  """
  @callback cast(any()) ::
              {:ok, term()} | :error | {:error, String.t()} | {:error, DataSchema.Errors.t()}
end
