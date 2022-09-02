# Changelog for version 0.2.x

## 0.4.1

### Enhancement

Adds docs about the `empty_values` option.

## 0.4.0

### Enhancement

Added an option called `empty_values` which allows you to specify per field what should be considered empty.
For example if you have a list of things you can supply an option like:

```elixir
defmodule Something do
  import DataSchema, only: [data_schema: 1]

  data_schema(
    list_of: {:list, "list", StringType, optional?: false, empty_values: [[]]}
  )
end
```

To maintain backwards compatability `nil` is always considered "empty" but you can optionally add more.

To support this we have changed the wording of some of the errors when the check fails.

## 0.3.2

### Bug Fix

The `DataSchema.flatten_errors/1` function was erroneously flipping the path to the error. This has now been fixed.

## 0.3.1

### Improvement

This release adds three new public functions:

* `DataSchema.to_runtime_schema/1`
* `DataSchema.flatten_errors/1`
* `DataSchema.to_error_tuple/1`

These allow for schema reflection and make working with errors easier.

## 0.3.0

### Improvement

We now handle errors returned from cast functions by returning a `%DataSchema.Errors{}` for them, which will effectively point to the field that error'd. Previously we were only doing that for non null errors for some reason! to_struct now never returns `:error` only.

## 0.2.9

### Improvement

Allows for using a MFA tuple ({module, function, arguments}) as a casting function in a data schema. The value extracted from the input data will be set as the first argument in the arguments list.

## 0.2.8

### Improvement

Improve the error message when the cast function does not return an okay tuple.

## 0.2.7

### Improvement

Bump ex_doc to get newer looking docs.

## 0.2.6

### Bug fix

Fix schema validations and error message.

We were not allowing valid schema syntax for an inline schema (ie a
runtime schema that is provided at compile time), and our error message
was wrong.

Now we correctly allow:

```elixir
has_many: {:dep, "./Dep", {%{}, @place_schema}},
has_one: {:arrival, "./Arrival", {%{}, @place_schema}},
```

And similar. The last fix had a bug in it this one actually fixes it.

## 0.2.5

### Bug fix

Fix schema validations and error message.

We were not allowing valid schema syntax for an inline schema (ie a
runtime schema that is provided at compile time), and our error message
was wrong.

Now we correctly allow:

```elixir
has_many: {:dep, "./Dep", {%{}, @place_schema}},
has_one: {:arrival, "./Arrival", {%{}, @place_schema}},
```

And similar.

## 0.2.4

### Feature

Enables Runtime schemas and parsing to a bare map. Check out the provided docs and livebook for more info!

## 0.2.3

### Bug fix

Ensures we call `Code.ensure_loaded?` before checking if function is exported. This was causing problems when running tests.

## 0.2.2

### Bug fix

We were not creating the nested errors correctly for has_many and has_one, now we do.
We also were removing `nil`s when they were allowed for `:list_of`, we now don't.

## 0.2.1

### Bug fix

Previously we could not use a `:list_of` field on an inline `:aggregate` field. This fixes that.

## 0.2.0

This represents a major change with lots of functionality re-thought an simplified. I would be highly surprised if anyone is even using this library at this point but it is good practice to mention it is a breaking change.

### Breaking Changes

- `to_struct!/2` has been removed. `to_struct/2` now expects casting functions to return okay / error tuples.
- Cast behaviour added and enforces that cast fns return okay / error tuples
- `data_schema/2` has been removed. Instead you now supply a data_accessor via a module attribute on the schema.
- `to_struct/2` now returns an `{:error, DataSchema.Error.t()}` at the first time an error is encountered. If the field that failed is nested the error will be a nested error that points to the field that failed. This makes it easy to see what the error was, but might make it harder to traverse errors later. We will see.
- `DataSchema.AccessBehaviour` has changed to remove the `aggregate` function. Because of the change in how aggregates work this is now no longer needed here.
- Aggregate fields now either specify a nested schema or supply fields (effectively a schemaless schema). This means we can have aggregates which include lists of things in the aggregation.
- `list_of` has changed a little in that you should not really use `list_of` for a list of nested schemas. You still can but it leads to possible problems like having two sets of options sent to the to_struct function making it unclear what would happen.

### Enhancements

So many good things including better docs and the like. But:

- Adds a `has_many` field. This is in addition to the `list_of` field and there are good reasons for having them all which I will explain in some docs soon.
- Adds an `DataSchema.Erros` struct to communicate errors.
- More and better schema validations on schema create - we raise some nice errors in the case of misconfigured schemas.

## 0.0.2

### Enhancement

Much better docs and some ex_doc niceties added.

### Breaking Change

* This changes the name of `to_struct` to `to_struct!`
* adds a `to_struct` function that lets us return error tuples from casting functions and have the casting halt and return the error.

## 0.0.1

### Enhancement

Implements a first stab at data schemas. Check the docs for how they work.


