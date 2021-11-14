# DataSchema

<!-- We def want a livebook for this. So much easier to explain. -->

Data schemas are declarative descriptions of how to create a struct from some input data. You can set up different schemas to handle different kinds of input data.

Let's think of creating a struct as taking some source data and turning it into the desired struct. To do this we need to know at least three things:

1. The keys of the desired struct
2. The types of the values for each of the keys
3. Where / how to get the data for each value from the source data.

Turning the source data into the correct type defined by the schema will often require casting, so to cater for that the type definitions are casting functions. Let's look at a simple field example

```elixir
field {:content, "text", &cast_string/1}
#       ^          ^                ^
# struct field     |                |
#     path to data in the source    |
#                            casting function
```

This says in the source data there will be a field called `:text`. When creating a struct we should get the data under that field and pass it too `cast_string/1`. The result of that function will be put in the resultant struct under the key `:content`.

There are 4 kinds of struct fields we could want:

1. `field`     - The value will be a casted value from the source data.
2. `list_of`   - The value will be a list of casted values created from the source data.
3. `has_one`   - The value will be created from a nested data schema.
4. `aggregate` - The value will a casted value formed from multiple bits of data in the source.

To see this better let's look at a very simple example. Assume our input data looks like this:

```elixir
source_data = %{
  "content" => "This is a blog post",
  "comments" => [%{"text" => "This is a comment"},%{"text" => "This is another comment"}],
  "draft" => %{"content" => "This is a draft blog post"},
  "date" => "2021-11-11",
  "time" => "14:00:00",
  "metadata" => %{ "rating" => 0}
}
```

And now let's assume the struct we wish to make is this one:

```elixir
%BlogPost{
  content: "This is a blog post",
  comments: [%Comment{text: "This is a comment"}, %Comment{text: "This is another comment"}]
  draft: %DraftPost{content: "This is a draft blog post"}}
  post_datetime: ~N[2020-11-11 14:00:00]
}
```

As we mentioned before we want to be able to handle multiple different kinds of source data in different schemas. For each type of source data we want to be able to specify how you access the data for each field type, we do that by providing a data accessor module that implements the `DataAccessBehaviour` when we create the schema.

When creating the struct DataSchema will call the relevant function for the field we are creating, passing it the source data and the path to the value(s) in the source.

Given that the source data is a map, we can pass a simple MapAccessor:

```elixir
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
end
```

So now we can define the following data_schemas

```elixir
defmodule DraftPost do
  import DataSchema, only: [data_schema: 2]

  data_schema([
    field: {:content, "content", DataSchema.String}
  ], MapAccessor)
end

defmodule Comment do
  import DataSchema, only: [data_schema: 2]

  data_schema([
    field: {:text, "text", DataSchema.String}
  ], MapAccessor)

  def cast(data) do
    DataSchema.to_struct(data, __MODULE__)
  end
end

defmodule BlogPost do
  import DataSchema, only: [data_schema: 2]

  data_schema([
    field: {:content, "content", DataSchema.String},
    list_of: {:comments, "comments", Comment},
    has_one: {:draft, "draft", DraftPost},
    aggregate: {:post_datetime, %{date: "date", time: "time"}, &BlogPost.to_datetime/1},
  ], MapAccessor)

  def to_datetime(%{date: date, time: time}) do
    date = Date.from_iso8601!(date)
    time = Time.from_iso8601!(time)
    {:ok, datetime} = NaiveDateTime.new(date, time)
    datetime
  end
end
```

But we can clean this up a bit with currying. Instead of passing `MapAccessor` every time we create a schema we can define a helper function like so:

```elixir
defmodule MapAccessor do
  ...
  defmacro map_schema(fields) do
    quote do
      require DataSchema
      DataSchema.data_schema(unquote(fields), MapAccessor)
    end
  end
  ...
end
```

Then change our schema definitions to look like this:

```elixir
defmodule DraftPost do
  import MapAccessor, only: [map_schema: 1]

  map_schema([
    field: {:content, "content", DataSchema.String}
  ])
end

defmodule Comment do
  import MapAccessor, only: [map_schema: 1]

  map_schema([
    field: {:text, "text", DataSchema.String}
  ])

  def cast(data) do
    DataSchema.to_struct(data, __MODULE__)
  end
end

defmodule BlogPost do
  import MapAccessor, only: [map_schema: 1]

  map_schema([
    field: {:content, "content", DataSchema.String},
    list_of: {:comments, "comments", Comment},
    has_one: {:draft, "draft", DraftPost},
    aggregate: {:post_datetime, %{date: "date", time: "time"}, &BlogPost.to_datetime/1},
  ])

  def to_datetime(%{date: date_string, time: time_string}) do
    date = Date.from_iso8601!(date_string)
    time = Time.from_iso8601!(time_string)
    {:ok, datetime} = NaiveDateTime.new(date, time)
    datetime
  end
end
```

Now we can create our struct from the source data:

```elixir
source_data = %{
  "content" => "This is a blog post",
  "comments" => [%{"text" => "This is a comment"},%{"text" => "This is another comment"}],
  "draft" => %{"content" => "This is a draft blog post"},
  "date" => "2021-11-11",
  "time" => "14:00:00",
  "metadata" => %{ "rating" => 0}
}

DataSchema.to_struct(source_data, BlogPost)

# => %BlogPost{
#  content: "This is a blog post",
#  comments: [%Comment{text: "This is a comment"}, %Comment{text: "This is another comment"}]
#  draft: %DraftPost{content: "This is a draft blog post"}}
#  post_datetime: ~N[2020-11-11 14:00:00]
#}
```

### XML Schemas

Now let's imagine instead that our source data was XML. What would it require to enable that? First a new Xpath data accessor:

```elixir
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
```

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
  import XpathAccessor, only: [xpath_schema: 1]

  xpath_schema([
    field: {:content, "./Content/text()", DataSchema.String}
  ])
end

defmodule Comment do
  import XpathAccessor, only: [xpath_schema: 1]

  xpath_schema([
    field: {:text, "./text()", DataSchema.String}
  ])

  def cast(data) do
    DataSchema.to_struct(data, __MODULE__)
  end
end

defmodule BlogPost do
  import XpathAccessor, only: [xpath_schema: 1]

  xpath_schema([
    field: {:content, "/Blog/Content/text()", DataSchema.String},
    list_of: {:comments, "//Comment", Comment},
    has_one: {:draft, "/Blog/Draft", DraftPost},
    aggregate: {:post_datetime, %{date: "/Blog/@date", time: "/Blog/@time"}, &BlogPost.to_datetime/1},
  ])

  def to_datetime(%{date: date_string, time: time_string}) do
    date = Date.from_iso8601!(date_string)
    time = Time.from_iso8601!(time_string)
    {:ok, datetime} = NaiveDateTime.new(date, time)
    datetime
  end
end
```

And now we can transform:

```elixir
DataSchema.to_struct(source_data, BlogPost)
# => %BlogPost{
#   comments: [
#     %Comment{text: "This is a comment"},
#     %Comment{text: "This is another comment"}
#   ],
#   content: "This is a blog post",
#   draft: %DraftPost{content: "This is a draft blog post"},
#   post_datetime: ~N[2021-11-11 14:00:00]
# }
```

### JSONPath Schemas

This is left as an exercise for the reader but hopefully you can see how you could extend this idea to allow for json data and JSONPaths pointing to the data in the schemas.

## Installation

[available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `data_schema` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:data_schema, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/data_schema](https://hexdocs.pm/data_schema).

