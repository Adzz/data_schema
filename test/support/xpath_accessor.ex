defmodule XpathAccessor do
  @moduledoc """
  Just for testing but an example of what you could do if you are reading this.
  """
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
  def has_many(data, path) do
    SweetXml.xpath(data, ~x"#{path}"l)
  end

  @impl true
  def aggregate(data, path) do
    SweetXml.xpath(data, ~x"#{path}"s)
  end
end

# We also wont to know about errors probably. Right now where we stop at the first error
# we don't collect them but we probably should.
# That would involve constructing an error in the case and reducing that instead. but
# we can storre the key of the struct that produced the error for easiness in to_struct
# later..

# this is where we get to "the key should be included in the error" thing because then
# error messages are better. if this failed it'd be hard to know why.
# %DataSchema.CastErrors{errors: [
# {field, message},
# {field, message},
# {field, message},
# ]} ->
# raise "error: #{message}"
# {:ok, struct} -> struct
# end

# We can either put the path into the error message, or the struct key name, and we
# can do the key name in the to_struct function.
