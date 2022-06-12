defmodule DataSchema.XML.SaxyTest do
  use ExUnit.Case, async: true

  describe "handle_event" do
    test "creating a DOM with one root node works" do
      schema = %{
        "A" => %{
          :text => true,
          {:attr, "attr"} => true
        }
      }

      xml = "<A attr=\"1\">text</A>"
      assert {:ok, form} = DataSchema.XML.Saxy.parse_string(xml, schema)
      assert form == {"A", [{"attr", "1"}], ["text"]}
    end

    test "we skip xml nodes that are not in the schema" do
      schema = %{
        "A" => %{
          :text => true,
          {:attr, "attr"} => true
        }
      }

      xml = """
      <A attr=\"1\">
        <B />
        text
        <C>
          this is C
        </C>
      </A>
      """

      assert {:ok, form} = DataSchema.XML.Saxy.parse_string(xml, schema)
      assert form == {"A", [{"attr", "1"}], ["\n  ", "\n  text\n  ", "\n"]}
    end

    test "duplicate node names are not a problem when skipping" do
      schema = %{
        "A" => %{
          :text => true,
          {:attr, "attr"} => true
        }
      }

      xml = """
      <A attr=\"1\">
        <B>
          <C>
          <B />
          </C>
        </B>
        text
      </A>
      """

      assert {:ok, form} = DataSchema.XML.Saxy.parse_string(xml, schema)
      assert form == {"A", [{"attr", "1"}], ["\n  ", "\n  text\n"]}
    end
  end
end
