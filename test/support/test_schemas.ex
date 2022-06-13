defmodule A do
  import DataSchema, only: [data_schema: 1]

  data_schema(
    field: {:a, "a", String},
    list_of: {:b, "b", String}
  )
end

defmodule AOpts do
  import DataSchema, only: [data_schema: 1]

  data_schema(
    field: {:a, "a", String, optional?: true},
    list_of: {:b, "b", String, optional?: true}
  )
end

defmodule C do
  import DataSchema, only: [data_schema: 1]

  data_schema(
    field: {:a, "a", String},
    list_of: {:b, "b", String}
  )
end

defmodule D do
  import DataSchema, only: [data_schema: 1]

  data_schema(
    field: {:a, "a", String},
    list_of: {:b, "b", String},
    has_one: {:c, "c", C}
  )
end

defmodule AHas do
  import DataSchema, only: [data_schema: 1]

  data_schema(
    has_one: {:d, "d", D},
    has_many: {:c, "c", C}
  )
end

defmodule COpts do
  import DataSchema, only: [data_schema: 1]

  data_schema(
    field: {:a, "a", String},
    list_of: {:b, "b", String}
  )
end

defmodule DOpts do
  import DataSchema, only: [data_schema: 1]

  data_schema(
    field: {:a, "a", String},
    list_of: {:b, "b", String},
    has_one: {:c, "c", COpts}
  )
end

defmodule AHasOpts do
  import DataSchema, only: [data_schema: 1]

  data_schema(
    has_one: {:d, "d", DOpts},
    has_many: {:c, "c", COpts}
  )
end
