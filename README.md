# DataSchema

<!-- We def want a livebook for this. So much easier to explain. -->

Data schemas are declarative descriptions of how to create a struct from some input data. You can set up different schemas to handle different kinds of input data. By default we assume the incoming data is a map, but you can configure schemas to work with any arbitrary data input including XML and json.

Data Schemas really shine when working with API responses - converting the response into trusted internal data easily and efficiently.

## Creating A Simple Schema

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

There are 5 kinds of struct fields we could want:

1. `field`     - The value will be a casted value from the source data.
2. `list_of`   - The value will be a list of casted values created from the source data.
3. `has_one`   - The value will be created from a nested data schema (so will be a struct)
4. `has_many`  - The value will be created by casting a list of values into a data schema.
(You end up with a list of structs defined by the provided schema). Similar to has_many in ecto
5. `aggregate` - The value will a casted value formed from multiple bits of data in the source.

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

We can describe the following schemas to enable this:

```elixir
defmodule DraftPost do
  import DataSchema, only: [data_schema: 1]

  data_schema([
    field: {:content, "content", &{:ok, to_string(&1)}}
  ])
end

defmodule Comment do
  import DataSchema, only: [data_schema: 1]

  data_schema([
    field: {:text, "text", &{:ok, to_string(&1)}}
  ])
end

defmodule BlogPost do
  import DataSchema, only: [data_schema: 1]

  data_schema([
    field: {:content, "content", &{:ok, to_string(&1)}},
    has_many: {:comments, "comments", Comment},
    has_one: {:draft, "draft", DraftPost},
    aggregate: {:post_datetime, %{date: "date", time: "time"}, &BlogPost.to_datetime/1},
  ])

  def to_datetime(%{date: date, time: time}) do
    date = Date.from_iso8601!(date)
    time = Time.from_iso8601!(time)
    NaiveDateTime.new(date, time)
  end
end
```

Then to transform some input data into the desired struct we can call `DataSchema.to_struct/2` which works recursively to transform the input data into the struct defined by the schema.

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
# This will output the following:

%BlogPost{
  content: "This is a blog post",
  comments: [%Comment{text: "This is a comment"}, %Comment{text: "This is another comment"}]
  draft: %DraftPost{content: "This is a draft blog post"}}
  post_datetime: ~N[2020-11-11 14:00:00]
}
```

## Different Source Data Types

As we mentioned before we want to be able to handle multiple different kinds of source data in our schemas. For each type of source data we want to be able to specify how you access the data for each field type. We do that by providing a "data accessor" (a module that implements the `DataSchema.DataAccessBehaviour`) when we create the schema. We do this by providing a `@data_accessor` on the schema. By default if you do not provide this module attribute we use `DataSchema.MapAccessor`. That means the above example is equivalent to doing the following:

```elixir
defmodule DraftPost do
  import DataSchema, only: [data_schema: 1]

  @data_accessor DataSchema.MapAccessor
  data_schema([
    field: {:content, "content", &{:ok, to_string(&1)}}
  ])
end

defmodule Comment do
  import DataSchema, only: [data_schema: 1]

  @data_accessor DataSchema.MapAccessor
  data_schema([
    field: {:text, "text", &{:ok, to_string(&1)}}
  ])
end

defmodule BlogPost do
  import DataSchema, only: [data_schema: 1]

  @data_accessor DataSchema.MapAccessor
  data_schema([
    field: {:content, "content", &{:ok, to_string(&1)}},
    has_many: {:comments, "comments", Comment},
    has_one: {:draft, "draft", DraftPost},
    aggregate: {:post_datetime, %{date: "date", time: "time"}, &BlogPost.to_datetime/1},
  ])

  def to_datetime(%{date: date, time: time}) do
    date = Date.from_iso8601!(date)
    time = Time.from_iso8601!(time)
    NaiveDateTime.new(date, time)
  end
end
```
When creating the struct DataSchema will call the relevant function for the field we are creating, passing it the source data and the path to the value(s) in the source. Our `DataSchema.MapAccessor` looks like this:

```elixir
defmodule DataSchema.MapAccessor do
  @behaviour DataSchema.DataAccessBehaviour

  @impl true
  def field(data = %{}, field) do
    Map.get(data, field)
  end

  @impl true
  def list_of(data = %{}, field) do
    Map.get(data, field)
  end

  @impl true
  def has_one(data = %{}, field) do
    Map.get(data, field)
  end

  @impl true
  def has_many(data = %{}, field) do
    Map.get(data, field)
  end
end
```

To save repeating `@data_accessor DataSchema.MapAccessor` on all of your schemas you could use a `__using__` macro like so:

```elixir
defmodule MapSchema do
  defmacro __using__(_) do
    quote do
      import DataSchema, only: [data_schema: 1]
      @data_accessor DataSchema.MapAccessor
    end
  end
end
```
Then use it like so:

```elixir
defmodule DraftPost do
  use MapSchema

  data_schema([
    field: {:content, "content", &{:ok, to_string(&1)}}
  ])
end
```

This means should we want to change how we access data (say we wanted to use `Map.fetch!` instead of `Map.get`) we would only need to change the accessor used in one place - inside the `__using__` macro. It also gives you a handy place to provide other functions for the structs that get created, perhaps implementing a default Inspect protocol implementation for example:

```elixir
defmodule MapSchema do
  defmacro __using__(opts) do
    skip_inspect_impl = Keyword.get(opts, :skip_inspect_impl, false)

    quote bind_quoted: [skip_inspect_impl: skip_inspect_impl] do
      import DataSchema, only: [data_schema: 1]
      @data_accessor DataSchema.MapAccessor

      unless skip_inspect_impl do
        defimpl Inspect do
          def inspect(struct, _opts) do
            "<" <> "#{struct.__struct__}" <> ">"
          end
        end
      end
    end
  end
end
```

This could help ensure you never log sensitive fields by requiring you to explicitly implement an inspect protocol for a struct in order to see the fields in it.

### XML Schemas

Now let's imagine instead that our source data was XML. What would it require to enable that? First a new Xpath data accessor:

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
  import DataSchema, only: [data_schema: 1]

  @data_accessor XpathAccessor
  data_schema([
    field: {:content, "./Content/text()", &{:ok, to_string(&1)}}
  ])
end

defmodule Comment do
  import DataSchema, only: [data_schema: 1]

  @data_accessor XpathAccessor
  data_schema([
    field: {:text, "./text()", &{:ok, to_string(&1)}}
  ])
end

defmodule BlogPost do
  import DataSchema, only: [data_schema: 1]

  @data_accessor XpathAccessor
  data_schema([
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

### JSONPath Schemas

This is left as an exercise for the reader but hopefully you can see how you could extend this idea to allow for json data and JSONPaths pointing to the data in the schemas.

### Guides

See the [docs](https://hexdocs.pm/data_schema/DataSchema.html) or the [guides in this repo](https://github.com/Adzz/data_schema/tree/main/guides) for more details.

### Contributing

**NB** Set the `MIX_ENV` to `:docs` when publishing the package. This will ensure that modules inside `test/support` wont get their documentation published with the library (as they are included in the :dev env).

```sh
MIX_ENV=docs mix hex.publish
```

You will also have to set that env if you want to run `mix docs`

```sh
MIX_ENV=docs mix docs
```

## Installation

[available in Hex](https://hex.pm/packages/data_schema), the package can be installed by adding `data_schema` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:data_schema, "~> 0.1.0"}
  ]
end
```
