defmodule DataSchema.Errors do
  @moduledoc """
  When we create a struct we either return the struct we were creating or we return this error.
  The error/errors that happened during struct creation are collected into this struct
  """
  @typedoc """
  An error is the struct key that caused the error and either an error message or a
  DataSchema.Errors struct in the case of nested error.
  """
  @type t :: %__MODULE__{errors: [{atom, String.t() | __MODULE__.t()}]}
  defstruct errors: []

  @doc """
  Adds an error to the given errors struct. The error is prepended to the list of current errors.
  """
  def add_error(%__MODULE__{} = errors, error) do
    %{errors | errors: [error | errors.errors]}
  end

  @doc """
  Turns the DataSchema.Errors struct into a flattened error tuple of path to field and
  error message

  ### Examples

      iex> error = %DataSchema.Errors{
      ...>    errors: [
      ...>      comments: %DataSchema.Errors{
      ...>        errors: [author:
      ...>          %DataSchema.Errors{
      ...>            errors: [name: "There was an error!"]
      ...>          }
      ...>        ]
      ...>      }
      ...>    ]
      ...>   }
      ...> DataSchema.Errors.flatten_errors(error)
      {:error, {[:name, :author, :comments], "There was an error!"}}
  """
  @type path_to_error :: [atom()]
  @type error_message :: String.t()
  @spec to_error_tuple(__MODULE__.t()) :: {:error, path_to_error, error_message}
  def to_error_tuple(%__MODULE__{} = error) do
    {:error, flatten_errors(error)}
  end

  @doc """
  Returns a tuple of the path to the problematic field and the error message.

  Usually errors are returned as nested `DataSchema.Errors` structs. This was to help
  cater for the possibility of collecting all errors, but right now we stop casting as
  soon as we error on a casting function, so errors are a little confusing. This function
  can be used to return a flattend error.

  ### Examples

      iex> error = %DataSchema.Errors{
      ...>    errors: [
      ...>      comments: %DataSchema.Errors{
      ...>        errors: [author:
      ...>          %DataSchema.Errors{
      ...>            errors: [name: "There was an error!"]
      ...>          }
      ...>        ]
      ...>      }
      ...>    ]
      ...>   }
      ...> DataSchema.Errors.flatten_errors(error)
      {[:name, :author, :comments], "There was an error!"}
  """
  def flatten_errors(%__MODULE__{} = error) do
    flatten_errors(error, {[], ""})
  end

  def flatten_errors(%__MODULE__{errors: [head | _]}, {path, msg}) do
    case head do
      {key, %DataSchema.Errors{} = error} -> flatten_errors(error, {[key | path], msg})
      {key, error_message} -> {[key | path], error_message}
    end
  end
end

# if we have a recursive error type it's easy to create errors and you can tell if you read
# it where the nested error is... but flattening that error gets tricky. IT depends what the
# user wants to do with it.

#   # Is this a good idea? Even needed? Shall we just not do recursive errors?
#   def flatten_error_messages(%__MODULE__{errors: []}), do: "No Errors!"

#   def flatten_error_messages(%__MODULE__{} = errors) do
#     do_flatten_error_messages(errors.errors, [[]])
#   end

#   def do_flatten_error_messages([], acc) do
#     # Enum.map(acc, &:lists.reverse/1)
#     # |> :lists.reverse()
#     acc
#   end

#   def do_flatten_error_messages([{field, string} | rest], [stuff | acc]) when is_binary(string) do
#     do_flatten_error_messages(rest, [ stuff, [field | stuff] | acc])
#   end

#   def do_flatten_error_messages([{field, %DataSchema.Errors{} = e} | rest], [stuff |acc]) do
#     field |> IO.inspect(limit: :infinity, label: "ffffff")
#     new_acc = do_flatten_error_messages(e.errors, [[field | stuff] | acc])
#     |> IO.inspect(limit: :infinity, label: "newaccc")
#     do_flatten_error_messages(rest, [ stuff | new_acc])
#   end
# end

# If we get an error from a nested field we should like nest the errors like so:
# %DataSchema.Errors{
#   errors: [
#     bar: "Field was marked as not null but was found to be null.",
#     foo: %DataSchema.Errors{
#       errors: [
#         comment: "Field was marked as not null but was found to be null."
#       ],
#     }
#   ]
# }
