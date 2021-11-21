### XML Schemas

Let's imagine that we have some XML that we wish to turn into a struct. What would it require to enable that? First a new Xpath data accessor:

```elixir
defmodule XpathAccessor do
  @behaviour DataSchema.DataAccessBehaviour
  import SweetXml, only: [sigil_x: 2]

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
end

defmodule DataSchema.Xpath do
  defmacro xpath_schema(fields) do
    quote do
      require DataSchema
      DataSchema.data_schema(unquote(fields), XpathAccessor)
    end
  end
end
```

As we can see our accessor uses the library [Sweet XML](https://github.com/kbrw/sweet_xml) to access the XML. That means if we wanted to change the library later we would only need to alter this one module for all of our schemas to benefit from the change.

Our source data looks like this:

```elixir
source_data = """
<Blog date="2021-11-11" time="14:00:00">
  <Content>This is a blog post</Content>
  <Comments>
    <Comment>This is a comment</Comment>
    <Comment>This is another comment</Comment>
  </Comments>
  <Draft>
    <Content>This is a draft blog post</Content>
  </Draft>
</Blog>
"""
```

Let's define our schemas like so:

```elixir
defmodule DraftPost do
  import DataSchema.Xpath, only: [xpath_schema: 1]

  xpath_schema([
    field: {:content, "./Content/text()", &{:ok, to_string(&1)}}
  ])
end

defmodule Comment do
  import DataSchema.Xpath, only: [xpath_schema: 1]

  xpath_schema([
    field: {:text, "./text()", &{:ok, to_string(&1)}}
  ])
end

defmodule BlogPost do
  import DataSchema.Xpath, only: [xpath_schema: 1]

  xpath_schema([
    field: {:content, "/Blog/Content/text()", &{:ok, to_string(&1)}},
    has_many: {:comments, "//Comment", Comment},
    has_one: {:draft, "/Blog/Draft", DraftPost},
    aggregate: {:post_datetime, %{date: "/Blog/@date", time: "/Blog/@time"}, &BlogPost.to_datetime/1},
  ])

  def to_datetime(%{date: date_string, time: time_string}) do
    date = Date.from_iso8601!(date_string)
    time = Time.from_iso8601!(time_string)
    NaiveDateTime.new(date, time)
  end
end
```

And now we can transform:

```elixir
source_data = """
<Blog date="2021-11-11" time="14:00:00">
  <Content>This is a blog post</Content>
  <Comments>
    <Comment>This is a comment</Comment>
    <Comment>This is another comment</Comment>
  </Comments>
  <Draft>
    <Content>This is a draft blog post</Content>
  </Draft>
</Blog>
"""

DataSchema.to_struct(source_data, BlogPost)

# This will output:

 %BlogPost{
   comments: [
     %Comment{text: "This is a comment"},
     %Comment{text: "This is another comment"}
   ],
   content: "This is a blog post",
   draft: %DraftPost{content: "This is a draft blog post"},
   post_datetime: ~N[2021-11-11 14:00:00]
 }
```
