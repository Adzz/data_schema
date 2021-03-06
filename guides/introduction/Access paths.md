# Access Paths

Let’s look back at our map version.

```elixir
input = %{
  "content" => "This is a blog post",
  "comments" => [%{"text" => "This is a comment"},%{"text" => "This is another comment"}],
  "draft" => %{"content" => "This is a draft blog post"},
  "date" => "2021-11-11",
  "time" => "14:00:00",
  "metadata" => %{ "rating" => 0}
}
```

We could define a data accessor that looks like this:

```elixir
defmodule AccessDataAccessor do
  @behaviour DataSchema.DataAccessBehaviour

  @impl true
  def field(data, path) do
    get_in(data, path)
  end

  @impl true
  def list_of(data, path) do
    get_in(data, path)
  end

  @impl true
  def has_one(data, path) do
    get_in(data, path)
  end

  @impl true
  def has_many(data, path) do
    get_in(data, path)
  end
end
```
Now we can define our schema:

```elixir
defmodule Blog do
  import DataSchema, only: [data_schema: 1]

  @data_accessor AccessDataAccessor
  data_schema([
    list_of: {:comments, ["comments", Access.all(), "text"], &{:ok, to_string(&1)}},
  ])
end
```

And create a struct from this:

```elixir
input = %{
  "content" => "This is a blog post",
  "comments" => [%{"text" => "This is a comment"},%{"text" => "This is another comment"}],
  "draft" => %{"content" => "This is a draft blog post"},
  "date" => "2021-11-11",
  "time" => "14:00:00",
  "metadata" => %{ "rating" => 0}
}
DataSchema.to_struct(input, Blog)
# Returns:
{:ok, %Blog{comments: ["This is a comment", "This is another comment"]}}
```
