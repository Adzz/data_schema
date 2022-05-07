defmodule DataSchema.SaxyStructHandlerTest do
  use ExUnit.Case, async: true

  defmodule AnotherNode do
    import DataSchema
    @data_accessor DataSchema.SaxyStructHandlerAccessor
    data_schema(field: {:child, ["Child"], DataSchema.String, optional?: true})
  end

  defmodule ParentNode do
    import DataSchema
    @data_accessor DataSchema.SaxyStructHandlerAccessor
    data_schema(
      field: {:price, ["ParentNode", "@price"], DataSchema.String, optional?: true},
      field: {:my_node, ["ParentNode", "MyNode", "text()"], DataSchema.String, optional?: true},
      has_one: {:another_node, ["ParentNode", "AnotherNode"], AnotherNode, optional?: true}
    )
  end

  describe "Querying for data" do
    test "simple case where it's just nodes or text()." do
      xml = """
      <ParentNode price="1"><MyNode>mynode</MyNode><AnotherNode><Child>Stuff</Child></AnotherNode></ParentNode>
      """

      {:ok, x} = DataSchema.Saxy.StructHandler.parse_string(xml)

      assert x == %DataSchema.XMLNode{
               attributes: [%DataSchema.XMLAttr{name: "price", value: "1"}],
               content: [
                 %DataSchema.XMLNode{attributes: [], content: ["mynode"], name: "MyNode"},
                 %DataSchema.XMLNode{
                   attributes: [],
                   content: [
                     %DataSchema.XMLNode{attributes: [], content: ["Stuff"], name: "Child"}
                   ],
                   name: "AnotherNode"
                 }
               ],
               name: "ParentNode"
             }

      DataSchema.to_struct(x, ParentNode)
      |> IO.inspect(limit: :infinity, label: "")
    end
  end
end
