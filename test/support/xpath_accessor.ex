defmodule XpathAccessor do
  @behaviour DataSchema.DataAccessBehaviour
  import SweetXml, only: [sigil_x: 2]

  defmacro xpath_schema(fields) do
    quote do
      require DataSchema
      DataSchema.data_schema(unquote(fields), XpathAccessor)
    end
  end

  @impl true
  def field(data, path) do
    SweetXml.xpath(data, ~x"#{path}"s)
  end

  @impl true
  def list_of(data, path) do
    SweetXml.xpath(data, ~x"#{path}"l)
  end

  @impl true
  def has_one(data, path) do
    SweetXml.xpath(data, ~x"#{path}")
  end

  @impl true
  def aggregate(data, path) do
    SweetXml.xpath(data, ~x"#{path}"s)
  end
end
