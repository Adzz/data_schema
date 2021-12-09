# Todo List

- schemaless to_struct - this might be as simple as exposing the do_to_struct fn and changing the name, need to look. But would be cool to be able to have schemas be runtime data. We sort of have that from aggregate fields so feels like it wont be a massive jump. Questions are - do we still need a struct passed in or does it just create a map? If it requires a struct name then what is the name of it? and like why not just create a schema at that point? Either the struct has to exist already OR we create a map. Creating a map is not a bad idea I think.... using an existing struct could be good if you wanted to define one struct for many different input data types.... Though be good to have docs on why having different schemas with the same thing keys could be good. If we do the passed in struct would it be an update/override situation or just all keys? there would be no validation that the struct we were being passed has the keys that the schema defines so we'd have to handle that in some way - probably just raise but seems like it adds overhead. We should also add an optional "validate_schema" thing that you can call for schemaless fields which will bail out before to_struct. This simulates what happens when we create a schema normally... Should this be a macro? IS it more a dev aid? ALSO can we specify a DataSchema for valid schema fields.... meta!
- add mad tests... For optional?, not. Aggregate fields inline and not inline. For when accessor returns nil for each field and for when the cast fn returns nil for all fields and cases.
- Fix the doc below to make sense.
- implement traverse errors if we keep the recursive error thing.
- collect_errors version of to_struct using the above error struct.
- Livebook for the repo (make the guides livebooks that would mean they are easier to test too.)
- BENCHAMRK against Ecto embedded schemas? Against a simpler version of the to_struct fn?
- generally improve perf... Probably if we include collect errors that means making that a separate fn.

- is there a place for `aggregate_many` ? This would aid the use case where we wish to get a field from somewhere else and provide it to each of a list"

FOR EXAMPLE:


# It's tricky to know for sure without getting my head round your use case more but it feels like you can get a fair bit of what you want. I'd recommend having a play!

# I would say that when validations come from a combination of fields, you can still wrap this up into a casting function. Let's take a tricky example:

# ```elixir
# %{
#   "port" => "8080",
#   "firewall" => %{
#     "dnat" => %{
#       "nat-in" => [
#         %{
#           "dport" => "1",
#           "proto" => "tcp"
#         },
#         %{
#           "dport" => "8080",
#           "proto" => "tcp"
#         }
#       ]
#     }
#   }
# }
# ```

# Imagine that for the sake of example `port` and `dport` need to be equal. In our example that would make the first `nat-in` invalid, but the second on would be fine.

# Using DataSchema I would use an `:aggregate` field to group together all of the bits of data needed to determine whether a field can be considered valid. To help support this I would first use an `Access` data accessor. This allows me to use access paths to query for data in the input:

# ```elixir
defmodule AccessDataAccessor do
  @behaviour DataSchema.DataAccessBehaviour

  @impl true
  def field(data, "./"), do: data
  def field(data, path), do: get_in(data, path)

  @impl true
  def list_of(data, "./"), do: data
  def list_of(data, path), do: get_in(data, path)

  @impl true
  def has_one(data, "./"), do: data
  def has_one(data, path), do: get_in(data, path)

  @impl true
  def has_many(data, "./"), do: data
  def has_many(data, path), do: get_in(data, path)
end

# ```
# Now the schemas:

# ```elixir
defmodule SchemaString do
  def cast(v), do: {:ok, to_string(v)}
end

defmodule NatIn do
  import DataSchema

  data_schema(
    field: {:dport, "dport", SchemaString},
    field: {:proto, "proto", SchemaString}
  )
end

defmodule Nat do
  import DataSchema

  @data_accessor AccessDataAccessor
  @dport_fields [
    field: {:port, ["port"], SchemaString},
    field: {:dport, ["dport"], SchemaString}
  ]
  data_schema(
    aggregate: {:dport, @dport_fields, &Nat.valid_dport/1},
    field: {:proto, ["proto"], SchemaString}
  )

  def cast(value), do: DataSchema.to_struct(value)
  def valid_dport(%{port: port, dport: port}), do: {:ok, port}
  def valid_dport(_), do: {:error, "NOPE!"}
end

defmodule Thing do
  import DataSchema

  @fields [
    field: {:port, ["port"], SchemaString},
    has_many: {:nats, ["firewall", "dnat", "nat-in"], NatIn}
  ]
  @data_accessor AccessDataAccessor
  data_schema(aggregate: {:nat_in, @fields, &Thing.to_nats/1})

  def to_nats(%{port: port, nats: nats}) do
    Enum.reduce_while(nats, {:ok, []}, fn nat, {:ok, acc} ->
      case DataSchema.to_struct(nat, Nat) do
        {:ok, nat} -> {:cont, {:ok, [nat | acc]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end
end

# ```
# Now we can try with different data:

# ```elixir
input = %{
  "port" => "8080",
  "firewall" => %{
    "dnat" => %{
      "nat-in" => [
        %{
          "dport" => "1",
          "proto" => "tcp"
        },
        %{
          "dport" => "8080",
          "proto" => "tcp"
        }
      ]
    }
  }
}

DataSchema.to_struct(input, Thing)
# => {:error, %DataSchema.Errors{errors: [nat_in: "port did not == dport, dport was: 1"]}}

input = %{
  "port" => "8080",
  "firewall" => %{
    "dnat" => %{
      "nat-in" => [
        %{
          "dport" => "8080",
          "proto" => "tcp"
        },
        %{
          "dport" => "8080",
          "proto" => "tcp"
        }
      ]
    }
  }
}

DataSchema.to_struct(input, Thing)



- inline schema fields for has_one / has_many - Probably not doing as need a nice way to add the name of the struct when it is inline... I don't think there is one particularly. The other option is to just make a map for inline schemas but seems worse for some reason. Think it's better than supplying a struct name though.


#### Historical context on why has_one / has_many are their own fields

You might think they could be encompassed by field and list_of but there are subtle reasons why not. One day I may fully explain the reasoning properly but for now here are the ramblings as I figured it out. I will make it make more sense later.

 if we recur that means list has to be a nested schema
 if we dont then there is the confusion with nested schemas implementing
 to_struct with different options from the usual.
 basically the options for to_struct stop becoming runtime "when you call then fn"
 options and become schema compile time options... unless you pass the options to
 all the cast fns which like... meh. Maybe.

 the alternative is that we add a list_of and a has_many / one is just for
 schemas. list_of is self explanatory and is better than just a field because it allows
 to_struct to handle the looping behaviour (ie halt or not).
 It also means you can have more generic types that work across input data types. So instead
 of all xmerl schemas having Xmerl.data types you can have them take a string and return
 a number or whatever.


 What we are learning is we want this function to be able to control the looping
 and the error behaviour. We don't want it to be possible to accidentally mix and
 match. And we want as a simple an interface as possible.

 The other issue is we want to be able to have different access behaviour for
 different field types. So although it may seem that a has_many is just a list_of
 it's actually not because with xmerl for example you want different access behaviour
 It might seem like the flexibility is desirable and it could be - maybe you do want to collect
 all errors sometimes but not others. It is more likely that it's a footgun AND it also ends
 up baking in the decision of whether you want to collect errors or not @ compile time (as that's
 when the schema is created.). Which is not as optimal. It seems more likely that one would
 want to have the collect errors option be decided at runtime AND that it should be consistent
 for all cast fns.

 In fact if you want the collect errors behaviour then you could enable it yourself by doing
 list_of with a cast fn that calls to_struct.

 So the answer is for sure list_of and has_many, le sigh.

 The tradeoff with has_many / has_one is that implementing non_null is trickier?
 not if it's a field option though. But it does mean you can't have higher level
 stuff outside of whatever the normal cast fn is. I'm not sure if that will be
 a problem/ there is probably a reason we switched to list_of???
 I guess you can always switch to list_of / field if you want more fine grained
 control.

 The question becomes "does non null" mean "non empty?".




#### integration tests ramble.

Aside. Data schemas are a good example of integration tests being valuable. You could take the stance that to_struct is unit tested here so you don't test it in your app. Doing that means  though that you don't have a great way to test that your schema is defined. Except testing that the __data_schema_fields looks right (which is good to do!). Problem is that you don't know if you wrote the schema wrong until you do to_struct.

So even though it's repeating tests, the best way to test the schema is to just actually use it with to_struct. So repeated testing is fine, actually.

If the call stack is deep there is a case for mocking some functions in it, but it matters less when data is immutable. so it's how we define a "unit".
