defmodule Thing do
  def find_node([], node_name, []), do: :not_found
  def find_node([], node_name, acc), do: acc

  def find_node([{node_name, _, _} = winner | rest], node_name, acc) do
    find_node(rest, node_name, [winner | acc])
  end

  def find_node([{_, _, _} | rest], node_name, acc) do
    find_node(rest, node_name, acc)
  end
end

large =
  0..100_001
  |> Enum.map(fn x ->
    {x, x, []}
  end)

1

inputs = %{
  "start" => 2,
  "middle" => 50_000,
  "end" => 100_000,
  "not_found" => 500_000
}

Benchee.run(
  %{
    "find" => fn key ->
      Enum.filter(large, fn
        {^key, _, _} -> true
        _ -> false
      end)
    end,
    "manual" => fn key ->
      Thing.find_node(large, key, [])
    end
  },
  parallel: 5,
  inputs: inputs
)
