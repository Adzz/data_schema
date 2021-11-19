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

# We should add to the docs "if you want null checks do this"
# def nullable(schema, nil), do: nil
# def nullable(schema, value), do: schema.cast(value)

# # for to_struct! ? ..... we shouldn't
# def non_null(schema, nil), do: raise "nope"
# def non_null(schema, value), do: schema.cast(value)

# do we need two to_structs because it means different casting functions? and
# therefore
# different schemas which is a nightmare.
# I think we only need to_struct/2 we can always raise after

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
