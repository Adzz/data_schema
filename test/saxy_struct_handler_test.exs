defmodule DataSchema.SaxyStructHandlerTest do
  use ExUnit.Case, async: true

  # TODO path validations - field must end in @attr or text()
  # has_many, has_one can't end in @attr or text()

  defmodule AnotherNode do
    import DataSchema
    @data_accessor DataSchema.SaxyStructHandlerAccessor
    data_schema(field: {:child, ["Child", "text()"], DataSchema.String, optional?: true})
  end

  defmodule Problem do
    import DataSchema
    @data_accessor DataSchema.SaxyStructHandlerAccessor
    data_schema(
      field: {:inner_content, ["Problem", "text()"], DataSchema.String, optional?: true},
      field: {:attr, ["Problem", "@attr"], DataSchema.String, optional?: true}
    )
  end

  defmodule ParentNode do
    import DataSchema
    @data_accessor DataSchema.SaxyStructHandlerAccessor
    data_schema(
      # field: {:price, ["ParentNode", "@price"], DataSchema.String, optional?: true},
      # field: {:my_node, ["ParentNode", "MyNode", "text()"], DataSchema.String, optional?: true},
      # has_one: {:another_node, ["ParentNode", "AnotherNode"], AnotherNode, optional?: true},
      # has_many: {:problems, ["ParentNode", "Problems"], Problem, optional?: true},
      list_of:
        {:problem_text, ["ParentNode", "Problems", "Problem", "text()"], &__MODULE__.upcase/1},
      list_of:
        {:problem_attr, ["ParentNode", "Problems", "Problem", "@attr"], &__MODULE__.upcase/1}
    )

    def upcase(string) do
      {:ok, String.upcase(string)}
    end
  end

  describe "Querying for data" do
    test "simple case where it's just nodes or text()." do
      xml = """
      <ParentNode price="1">
        <MyNode>mynode</MyNode>
        <AnotherNode>
          <Child>Stuff</Child>
        </AnotherNode>
        <Problems>
          <Problem >Problem 1</Problem>
          <Problem attr="3" attr="2">Problem 2</Problem>
          <Problem attr="1">Problem 2</Problem>
        </Problems>
      </ParentNode>
      """

      {:ok, x} = DataSchema.Saxy.StructHandler.parse_string(xml)

      # assert x == %DataSchema.XMLNode{
      #          attributes: [%DataSchema.XMLAttr{name: "price", value: "1"}],
      #          content: [
      #            "\n  ",
      #            %DataSchema.XMLNode{attributes: [], content: ["mynode"], name: "MyNode"},
      #            "\n  ",
      #            %DataSchema.XMLNode{
      #              attributes: [],
      #              content: [
      #                "\n    ",
      #                %DataSchema.XMLNode{attributes: [], content: ["Stuff"], name: "Child"},
      #                "\n  "
      #              ],
      #              name: "AnotherNode"
      #            },
      #            "\n  ",
      #            %DataSchema.XMLNode{
      #              attributes: [],
      #              content: [
      #                "\n    ",
      #                %DataSchema.XMLNode{
      #                  attributes: [%DataSchema.XMLAttr{name: "attr", value: "1"}],
      #                  content: ["Problem 1"],
      #                  name: "Problem"
      #                },
      #                "\n    ",
      #                %DataSchema.XMLNode{
      #                  attributes: [%DataSchema.XMLAttr{name: "attr", value: "2"}],
      #                  content: ["Problem 2"],
      #                  name: "Problem"
      #                },
      #                "\n  "
      #              ],
      #              name: "Problems"
      #            },
      #            "\n"
      #          ],
      #          name: "ParentNode"
      #        }

      DataSchema.to_struct(x, ParentNode)
      |> IO.inspect(limit: :infinity, label: "")
    end
  end
end
