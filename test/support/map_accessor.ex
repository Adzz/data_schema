defmodule MapAccessor do
  @behaviour DataSchema.DataAccessBehaviour

  @impl true
  def field(data, field) do
    Map.get(data, field)
  end

  @impl true
  def list_of(data, field) do
    Map.get(data, field)
  end

  @impl true
  def has_one(data, field) do
    Map.get(data, field)
  end

  @impl true
  def aggregate(data, field) do
    Map.get(data, field)
  end

  defmacro map_schema(fields) do
    quote do
      require DataSchema
      DataSchema.data_schema(unquote(fields), MapAccessor)
    end
  end
end
