defmodule DataSchema.MapAccessor do
  @moduledoc """
  Defines a way to use elixir maps as an input data source. This will `Map.get/2` the fields
  from the source data, meaning it will return nil in the case of the key being missing.
  """
  @behaviour DataSchema.DataAccessBehaviour

  @impl true
  @doc """
  Accesses the source data using `Map.get/2` when a `:field` type is encountered during
  struct creation. If the incoming data is not a map we will function clause error.
  """
  def field(data = %{}, field), do: Map.get(data, field)

  @impl true
  @doc """
  Accesses the source data using `Map.get/2` when a `:list_of` type is encountered during
  struct creation.
  """
  def list_of(data = %{}, field), do: Map.get(data, field)

  @impl true
  @doc """
  Accesses the source data using `Map.get/2` when a `:has_one` type is encountered during
  struct creation.
  """
  def has_one(data = %{}, field), do: Map.get(data, field)

  @impl true
  @doc """
  Accesses the source data using `Map.get/2` when an `:aggregate` type is encountered during
  struct creation.
  """
  def aggregate(data = %{}, field), do: Map.get(data, field)
end
