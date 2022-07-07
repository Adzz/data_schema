xml = File.read!(Path.expand("./large.xml"))

fields = DataSchema.to_runtime_schema(Duffel.Link.XMLParsing.Lufthansa.AirShopping)
defmodule Expand do
  def paths(fields, acc) do
    Enum.reduce(fields, acc, fn
      {:has_many, {_key, path, {_child_schema, child_fields}, _opts}}, acc ->
        # last = List.last(path)
        # path = path |> List.replace_at(-1, {:all, last})

        child_fields
        |> paths([])
        |> Enum.reduce(acc, fn
        {p, modifier}, accu ->
          [{path ++ p, modifier} | accu]
        end)

      {:has_many, {_key, path, {_child_schema, child_fields}}}, acc ->
        # last = List.last(path)
        # path = path |> List.replace_at(-1, {:all, last})

        child_fields
        |> paths([])
        |> Enum.reduce(acc, fn
        {p, modifier}, accu ->
          [{path ++ p, modifier} | accu]
        end)

      {:has_one, {_key, path, {_child_schema, child_fields}, _opts}}, acc ->
        # path = Enum.drop(path, -1)

        child_fields
        |> paths([])
        |> Enum.reduce(acc, fn
        {p, modifier}, accu ->
          [{path ++ p, modifier} | accu]
        end)

      {:has_one, {_key, path, {_child_schema, child_fields}}}, acc ->
        # path = Enum.drop(path, -1)

        child_fields
        |> paths([])
            |> Enum.reduce(acc, fn
        {p, modifier}, accu ->
          [{path ++ p, modifier} | accu]
        end)

      {:aggregate, {_key, child_fields, _cast_fn}}, acc ->
        paths(child_fields, acc)

      {:aggregate, {_key, child_fields, _cast_fn, _opts}}, acc ->
        paths(child_fields, acc)


      {_field, {_key, path, _cast_fn}}, acc ->
        [path | acc]

      {_field, {_key, path, _cast_fn, _opts}}, acc ->
        [path | acc]
    end)
  end
end

paths = Expand.paths(fields, [])

sorted = Enum.sort_by(paths, fn
  {path, _} -> path
end)

defmodule MapUtils do
  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  # Key exists in both maps, and both values are maps as well.
  # These can be merged recursively.
  defp deep_resolve(_key, left = %{}, right = %{}) do
    deep_merge(left, right)
  end

  defp deep_resolve(_key, {:all, left}, {:all, right}) do
    {:all, deep_merge(left, right)}
  end

  defp deep_resolve(_key, {:all, _left}, _right) do
    raise "?"
  end

  defp deep_resolve(_key, _left, {:all, _right}) do
    raise "?2"
  end

  defp deep_resolve(_key, _left, right) do
    right
  end
end

defmodule Tree do
  def create(paths) do
    Enum.reduce(paths, %{}, fn {path, modifier}, acc ->
      leaf = case modifier do
        {:attr, attr} -> %{ {:attr, attr} => true }
        :text -> %{text: true}
      end

      map =
        path
        # |> Enum.reverse()
        |> dedup_path([])
        # |> IO.inspect(label: :deduped)
        |> Enum.reduce(leaf, fn
          {:all, key}, accu -> %{key => {:all, accu}}
          key, accu -> %{key => accu}
        end)

      MapUtils.deep_merge(acc, map)
    end)
  end

  # dedups immediate neighbours only, also reverses the list which helps with the
  # next steps after it.

  def dedup_path([], acc) do
    acc
  end

  def dedup_path([key], acc) do
    [key | acc]
  end

  def dedup_path([head, {:all, head} | rest], acc) do
    dedup_path([{:all, head} | rest], acc)
  end

  def dedup_path([{:all, head}, head | rest], acc) do
    dedup_path([{:all, head} | rest], acc)
  end

  def dedup_path([head, head | rest], acc) do
    # If it is duplicated then we need to drop one
    # the next will be picked up in the next iteration.
    # I think if we have double dups this wont work, but
    # we wont have that (I think!!)
    dedup_path([head | rest], acc)
  end

  def dedup_path([head, next | rest], acc) do
    dedup_path([next | rest], [head | acc])
  end
end

slimmed_schema = Tree.create(sorted)

# What's better parse from scratch each time you want to pull data out
# Or parse everything once and then query it with different schemas?

Benchee.run(
  %{
    "normal simpleform" => fn  ->
      {:ok, simple} = Saxy.SimpleForm.parse_string(xml, [])
      {:ok, _x} = DataSchema.to_struct(simple, Duffel.Link.XMLParsing.Lufthansa.AirShopping)
    end,
    "Slimmed down simpleform" => fn  ->
      {:ok, simple} = DataSchema.XML.Saxy.parse_string(xml, slimmed_schema)
      {:ok, _y} = DataSchema.to_struct(simple, Duffel.Link.XMLParsing.Lufthansa.AirShopping)
    end,
    # "struct" => fn ->
    #   DataSchema.XML.SaxyStruct.parse_string(xml, struct_schema)
    # end
  },
  parallel: 5,
  memory_time: 5,
  reduction_time: 5
  # inputs: inputs
)
