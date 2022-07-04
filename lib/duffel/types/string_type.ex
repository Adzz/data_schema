defmodule Duffel.Link.DataSchema.StringType do
  @moduledoc """
  Provides a casting function that can be used in DataSchemas which turns a value into an
  string.
  """
  @behaviour DataSchema.CastBehaviour

  def cast(nil), do: {:ok, nil}
  def cast(value) when is_binary(value), do: {:ok, value}
  def cast(value), do: {:ok, to_string(value)}

  def cast(value, opts) do
    with {:ok, string} <- cast(value) do
      string =
        Enum.reduce(opts, string, fn
          _opt, nil ->
            nil

          :downcase, list when is_list(list) ->
            Enum.map(list, &String.downcase/1)

          :downcase, str ->
            String.downcase(str)

          :split, list when is_list(list) ->
            list

          :split, str ->
            pattern = :binary.compile_pattern(" ")
            String.split(str, pattern, trim: true)

          _opt, str ->
            str
        end)

      {:ok, string}
    end
  end
end
