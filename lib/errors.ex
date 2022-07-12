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

  @doc false
  def new({field, error}) do
    DataSchema.Errors.add_error(%__MODULE__{}, {field, error})
  end

  @default_error_message "There was an error!"
  @doc false
  def default_error(field) do
    DataSchema.Errors.add_error(%DataSchema.Errors{}, {field, @default_error_message})
  end

  @doc false
  @non_null_error_message "Field was marked as not null but was found to be null."
  def null_error(field) do
    DataSchema.Errors.add_error(%DataSchema.Errors{}, {field, @non_null_error_message})
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
      ...> DataSchema.Errors.to_error_tuple(error)
      {:error, {[:comments, :author, :name], "There was an error!"}}
  """
  @type path_to_error :: [atom()]
  @type error_message :: String.t()
  @spec to_error_tuple(__MODULE__.t()) :: {:error, {path_to_error, error_message}}
  def to_error_tuple(%__MODULE__{} = error) do
    {:error, flatten_errors(error)}
  end

  @doc """
  Returns an error tuple of the path to the problematic field and the error message.

  Usually errors are returned as nested `DataSchema.Errors` structs. This was to help
  cater for the possibility of collecting all errors, but right now we stop casting as
  soon as we error on a casting function, so errors are a little confusing. This function
  can be used to return a flattened error.

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
      {[:comments, :author, :name], "There was an error!"}
  """
  def flatten_errors(%__MODULE__{} = error) do
    {path, error} = do_flatten_errors(error, {[], ""})
    {Enum.reverse(path), error}
  end

  # Because we don't yet "collect" all errors we can ignore rest here and just to DFS.
  defp do_flatten_errors(%__MODULE__{errors: [head | _rest]}, {path, msg}) do
    case head do
      {key, %DataSchema.Errors{} = error} -> do_flatten_errors(error, {[key | path], msg})
      {key, error_message} when is_binary(error_message) -> {[key | path], error_message}
    end
  end
end
