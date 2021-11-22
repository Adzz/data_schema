# Casting Functions

All schemas take a casting function which is a function that receives a value from the input data. What you do with this is up to you but the casting function should return an `{:ok, value}` or `{:error, error}` or `:error`. See the `DataSchema.CastBehaviour` for more details.


TODO: talk about them, the cast behaviour, and what they should return. Also about how they interact with nulls.
